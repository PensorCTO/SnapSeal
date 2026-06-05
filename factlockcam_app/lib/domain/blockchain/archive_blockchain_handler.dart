import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/locator.dart';
import '../../data/supabase/seal_ledger_repository.dart';
import '../../data/supabase/supabase_client_handle.dart';

/// Backend interface for dispatching a notarization proof to the relay.
///
/// Polygon path is fire-and-forget from [VaultService]; callers must not
/// block UI on completion.
abstract class ArchiveBlockchainHandler {
  /// Returns the ledger transaction hash after notarization completes.
  Future<String> notarizeFileHash({
    required String fileHash,
    required String ownerSignature,
    required String deviceSignature,
  });
}

/// Delegates to [SealLedgerRepository.simulateChainNotarize] — synchronous
/// simulated chain for the default testing stand-in.
class SimulatedBlockchainHandler implements ArchiveBlockchainHandler {
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
class PolygonBlockchainHandler implements ArchiveBlockchainHandler {
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
      var detail = response.data?.toString() ?? 'unknown error';
      if (response.data is Map) {
        final map = response.data as Map;
        final error = map['error'];
        final message = map['message'];
        final missing = map['missing'];
        if (error is String && error.isNotEmpty) {
          detail = error;
          if (message is String && message.isNotEmpty) {
            detail = '$detail: $message';
          }
          if (missing is List && missing.isNotEmpty) {
            detail = '$detail (missing: ${missing.join(', ')})';
          }
        }
      }
      throw StateError(
        'anchor-relay failed (${response.status}): $detail',
      );
    }

    final data = response.data;
    if (data is Map) {
      final txHash = data['transactionHash'];
      if (txHash is String && txHash.trim().isNotEmpty) {
        final normalized = txHash.trim();
        if (_isSimulatedPolygonTxHash(normalized)) {
          throw StateError(
            'anchor-relay returned a simulated tx hash; configure '
            'ALCHEMY_API_URL and RELAYER_PRIVATE_KEY on Supabase.',
          );
        }
        return normalized;
      }
    }
    throw StateError('anchor-relay returned no transactionHash.');
  }
}

/// Hex prefix of UTF-8 `polygon-sim:` — legacy QA fallback, not a real tx.
bool _isSimulatedPolygonTxHash(String txHash) {
  return txHash.toLowerCase().startsWith('0x706f6c79676f6e2d73696d3a');
}

final blockchainHandlerProvider = Provider<ArchiveBlockchainHandler>(
  (ref) => getIt<ArchiveBlockchainHandler>(),
);
