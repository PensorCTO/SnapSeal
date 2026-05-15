import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/debug/debug_agent_ndjson.dart';
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
    await client.from('proof_ledger').insert(<String, dynamic>{
      'asset_hash': assetHash,
      'wallet_id': walletId,
      'device_signature': deviceSignature,
      'chain_tx_hash': chainTxHash,
    });
  }

  Future<void> uploadCourierEncryptedBlob({
    required String storagePath,
    required Uint8List encryptedBytes,
  }) async {
    final client = _requiredClient();
    final supabaseHost =
        Uri.tryParse(client.rest.url)?.host ?? 'unknown_host';
    // #region agent log
    await debugAgentNdjson(
      sessionId: 'aefb6a',
      hypothesisId: 'H1',
      location: 'seal_ledger_repository.dart:uploadCourierEncryptedBlob:start',
      message: 'courier_blob_upload_attempt',
      data: <String, Object?>{
        'bucket': 'courier-blobs',
        'supabase_host': supabaseHost,
        'storage_path_segments': storagePath.split('/').length,
        'payload_byte_length': encryptedBytes.lengthInBytes,
      },
    );
    // #endregion agent log

    try {
      await client.storage
          .from('courier-blobs')
          .uploadBinary(
            storagePath,
            encryptedBytes,
            fileOptions: const FileOptions(
              contentType: 'application/octet-stream',
              upsert: true,
            ),
          );
      // #region agent log
    } on StorageException catch (error) {
      await debugAgentNdjson(
        sessionId: 'aefb6a',
        hypothesisId: 'H1',
        location:
            'seal_ledger_repository.dart:uploadCourierEncryptedBlob:error',
        message: 'courier_blob_upload_failed',
        data: <String, Object?>{
          'error_type': 'StorageException',
          'status': error.statusCode,
          'error_message_contains_bucket': error.message.contains(
            'Bucket not found',
          ),
          'sanitized_storage_message': error.message.length > 200
              ? error.message.substring(0, 200)
              : error.message,
          'bucket': 'courier-blobs',
          'supabase_host': supabaseHost,
        },
      );
      rethrow;
    } catch (error) {
      await debugAgentNdjson(
        sessionId: 'aefb6a',
        hypothesisId: 'H3',
        location:
            'seal_ledger_repository.dart:uploadCourierEncryptedBlob:error_unknown',
        message: 'courier_blob_upload_failed',
        data: <String, Object?>{
          'error_type': error.runtimeType.toString(),
          'supabase_host': supabaseHost,
        },
      );
      // #endregion agent log
      rethrow;
    }

    await debugAgentNdjson(
      sessionId: 'aefb6a',
      hypothesisId: 'H4',
      location:
          'seal_ledger_repository.dart:uploadCourierEncryptedBlob:success',
      message: 'courier_blob_upload_success',
      data: <String, Object?>{
        'bucket': 'courier-blobs',
        'supabase_host': supabaseHost,
      },
    );
  }

  Future<String> getOrCreateCourierPackage({
    required String assetHash,
    required String verifierPassword,
    required String encodedVaultKey,
    required String fileExtension,
    required String storagePath,
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
