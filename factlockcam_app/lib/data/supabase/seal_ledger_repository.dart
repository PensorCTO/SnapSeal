import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/di/locator.dart';

import 'supabase_client_handle.dart';

final sealLedgerRepositoryProvider = Provider<SealLedgerRepository>(
  (ref) => getIt<SealLedgerRepository>(),
);

enum SealLedgerSyncStatus { synced, alreadySynced }

/// Active-wallet ledger (`seal_ledger`) plus ProofLock RPC/table surface
/// (`check_proof_status`, simulated chain notarization, `proof_ledger`).
class SealLedgerRepository {
  SealLedgerRepository(this._handle);

  final SupabaseClientHandle _handle;

  bool get isConfigured => _handle.client != null;

  Future<SealLedgerSyncStatus> syncAssetFingerprint(
    String assetFingerprint,
  ) async {
    final client = _requiredClient();
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No authenticated user for seal ledger sync.');
    }

    final walletId = await _getWalletId(client, userId);
    try {
      await client.from('seal_ledger').insert({
        'asset_fingerprint': assetFingerprint,
        'wallet_id': walletId,
      });
      return SealLedgerSyncStatus.synced;
    } on PostgrestException catch (error) {
      if (error.code != '23505') {
        rethrow;
      }

      final existing = await client
          .from('seal_ledger')
          .select('wallet_id')
          .eq('asset_fingerprint', assetFingerprint)
          .maybeSingle();
      if (existing != null && existing['wallet_id'] == walletId) {
        return SealLedgerSyncStatus.alreadySynced;
      }

      rethrow;
    }
  }

  /// ProofLock pre-flight: `'new' | 'anonymous' | 'owned_by_me' | 'owned_by_other'`.
  Future<String> checkProofStatus(String fileHash) async {
    final client = _requiredClient();
    final response = await client.rpc(
      'check_proof_status',
      params: <String, dynamic>{'p_file_hash': fileHash},
    );
    if (response is! String) {
      throw StateError('check_proof_status returned unexpected type.');
    }
    return response;
  }

  /// Testing stand-in for Polygon: writes [simulated_chain_ledger], returns tx id.
  Future<String> simulateChainNotarize({
    required String fileHash,
    required String deviceSignature,
  }) async {
    final client = _requiredClient();
    final response = await client.rpc(
      'simulate_chain_notarize',
      params: <String, dynamic>{
        'p_file_hash': fileHash,
        'p_device_signature': deviceSignature,
      },
    );
    if (response is! String) {
      throw StateError('simulate_chain_notarize returned unexpected type.');
    }
    return response;
  }

  Future<String?> fetchActiveEvmAddress() async {
    final client = _requiredClient();
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      return null;
    }
    final row = await client
        .from('profiles')
        .select('evm_address')
        .eq('id', userId)
        .maybeSingle();
    final address = row?['evm_address'] as String?;
    if (address == null || address.trim().isEmpty) {
      return null;
    }
    return address.trim();
  }

  Future<void> insertProofLedgerRow({
    required String assetHash,
    required String deviceSignature,
    required String chainTxHash,
  }) async {
    final client = _requiredClient();
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No authenticated user for proof ledger sync.');
    }
    final walletId = await _getWalletId(client, userId);
    final evmAddress = await fetchActiveEvmAddress();
    await client.from('proof_ledger').insert(<String, dynamic>{
      'asset_hash': assetHash,
      'wallet_id': walletId,
      'device_signature': deviceSignature,
      'chain_tx_hash': chainTxHash,
      'notarization_status': 'notarized',
      'evm_address': evmAddress,
    });
  }

  /// Polygon saga: insert a pending row before the relay finalizes `chain_tx_hash`.
  Future<void> insertPendingProofLedgerRow({
    required String assetHash,
    required String deviceSignature,
  }) async {
    final client = _requiredClient();
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No authenticated user for proof ledger sync.');
    }
    final walletId = await _getWalletId(client, userId);
    final evmAddress = await fetchActiveEvmAddress();
    await client.from('proof_ledger').insert(<String, dynamic>{
      'asset_hash': assetHash,
      'wallet_id': walletId,
      'device_signature': deviceSignature,
      'chain_tx_hash': null,
      'notarization_status': 'pending_notarization',
      'evm_address': evmAddress,
    });
  }

  Future<String?> fetchProofNotarizationStatus(String assetHash) async {
    final client = _requiredClient();
    final row = await client
        .from('proof_ledger')
        .select('notarization_status')
        .eq('asset_hash', assetHash)
        .maybeSingle();
    return row?['notarization_status'] as String?;
  }

  /// Returns the finalized ledger transaction hash when present.
  Future<String?> fetchProofChainTxHash(String assetHash) async {
    final client = _requiredClient();
    final row = await client
        .from('proof_ledger')
        .select('chain_tx_hash, notarization_status')
        .eq('asset_hash', assetHash)
        .maybeSingle();
    if (row == null) {
      return null;
    }
    final status = row['notarization_status'] as String?;
    if (status != null && status != 'notarized') {
      return null;
    }
    final txHash = row['chain_tx_hash'] as String?;
    if (txHash == null || txHash.trim().isEmpty) {
      return null;
    }
    return txHash.trim();
  }

  Future<void> syncEvmAddress(String evmAddress) async {
    final client = _requiredClient();
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No authenticated user for EVM address sync.');
    }
    await client
        .from('profiles')
        .update(<String, dynamic>{'evm_address': evmAddress})
        .eq('id', userId);
  }

  Future<void> uploadCourierEncryptedBlob({
    required String storagePath,
    required Uint8List encryptedBytes,
  }) async {
    final client = _requiredClient();
    await client.storage.from('courier-blobs').uploadBinary(
          storagePath,
          encryptedBytes,
          fileOptions: const FileOptions(
            contentType: 'application/octet-stream',
            upsert: true,
          ),
        );
  }

  Future<String> getOrCreateCourierPackage({
    required String assetHash,
    required String verifierPassword,
    required String encodedVaultKey,
    required String fileExtension,
    required String storagePath,
    String? contentMimeType,
    String? contentCategory,
    int? maxDownloads,
    int? linkTtlDays,
  }) async {
    final client = _requiredClient();
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No authenticated user for courier package creation.');
    }

    final response = await client.rpc(
      'get_or_create_courier_package',
      params: <String, dynamic>{
        'p_asset_hash': assetHash,
        'p_verifier_password': verifierPassword,
        'p_encoded_vault_key': encodedVaultKey,
        'p_file_extension': fileExtension,
        'p_storage_path': storagePath,
        if (contentMimeType != null && contentMimeType.isNotEmpty)
          'p_content_mime_type': contentMimeType,
        if (contentCategory != null && contentCategory.isNotEmpty)
          'p_content_category': contentCategory,
        if (maxDownloads != null) 'p_max_downloads': maxDownloads,
        if (linkTtlDays != null) 'p_link_ttl_days': linkTtlDays,
      },
    );
    if (response is! String || response.isEmpty) {
      throw StateError('get_or_create_courier_package returned no package id.');
    }
    return response;
  }

  SupabaseClient _requiredClient() {
    final client = _handle.client;
    if (client == null) {
      throw StateError(
        'Supabase is not configured. Run with --dart-define SUPABASE_URL=... '
        'and --dart-define SUPABASE_ANON_KEY=...',
      );
    }
    return client;
  }

  Future<String> _getWalletId(SupabaseClient client, String userId) async {
    final row = await client
        .from('profiles')
        .select('wallet_id')
        .eq('id', userId)
        .single();
    final walletId = row['wallet_id'] as String?;
    if (walletId == null || walletId.isEmpty) {
      throw StateError('No wallet_id found for current user.');
    }
    return walletId;
  }
}
