import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/locator.dart';
import '../../data/supabase/seal_ledger_repository.dart';
import '../../data/supabase/supabase_client_handle.dart';

/// Backend interface for dispatching a notarization proof to the relay.
///
/// Polygon path is fire-and-forget from [VaultService]; callers must not
/// block UI on completion.
abstract class VaultBlockchainHandler {
  /// Returns the ledger transaction hash after notarization completes.
  Future<String> notarizeFileHash({
    required String fileHash,
    required String ownerSignature,
    required String deviceSignature,
  });
}

/// Delegates to [SealLedgerRepository.simulateChainNotarize] — synchronous
/// simulated chain for the default testing stand-in.
class SimulatedBlockchainHandler implements VaultBlockchainHandler {
  SimulatedBlockchainHandler(this._ledger);

  final SealLedgerRepository _ledger;

  @override
  Future<String> notarizeFileHash({
    required String fileHash,
    required String ownerSignature,
    required String deviceSignature,
  }) {
    return _ledger.simulateChainNotarize(
      fileHash: fileHash,
      deviceSignature: deviceSignature,
    );
  }
}

/// Invokes the `anchor-relay` Edge Function with the signed payload.
class PolygonBlockchainHandler implements VaultBlockchainHandler {
  PolygonBlockchainHandler(this._handle);

  final SupabaseClientHandle _handle;

  @override
  Future<String> notarizeFileHash({
    required String fileHash,
    required String ownerSignature,
    required String deviceSignature,
  }) async {
    final client = _handle.client;
    if (client == null) {
      throw StateError('Supabase is not configured for anchor-relay.');
    }

    final response = await client.functions.invoke(
      'anchor-relay',
      body: <String, dynamic>{
        'asset_hash': fileHash,
        'owner_signature': ownerSignature,
        'device_signature': deviceSignature,
      },
    );

    if (response.status >= 400) {
      final detail = response.data?.toString() ?? 'unknown error';
      throw StateError(
        'anchor-relay failed (${response.status}): $detail',
      );
    }

    final data = response.data;
    if (data is Map) {
      final txHash = data['transactionHash'];
      if (txHash is String && txHash.trim().isNotEmpty) {
        return txHash.trim();
      }
    }
    throw StateError('anchor-relay returned no transactionHash.');
  }
}

final blockchainHandlerProvider = Provider<VaultBlockchainHandler>(
  (ref) => getIt<VaultBlockchainHandler>(),
);
