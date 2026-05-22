import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/locator.dart';
import '../../data/supabase/seal_ledger_repository.dart';
import 'vault_blockchain_handler.dart';
import 'wallet_service.dart';

/// Durable chain write path. Production: Polygon; today: Supabase-simulated ledger.
abstract class ChainNotarizer {
  Future<String> notarizeFileHash({
    required String fileHash,
    required String deviceSignature,
  });
}

final chainNotarizerProvider = Provider<ChainNotarizer>(
  (ref) => getIt<ChainNotarizer>(),
);

class SimulatedChainNotarizer implements ChainNotarizer {
  SimulatedChainNotarizer(this._ledger);

  final SealLedgerRepository _ledger;

  @override
  Future<String> notarizeFileHash({
    required String fileHash,
    required String deviceSignature,
  }) {
    if (!_ledger.isConfigured) {
      throw StateError('Supabase is not configured.');
    }
    return _ledger.simulateChainNotarize(
      fileHash: fileHash,
      deviceSignature: deviceSignature,
    );
  }
}

/// Wires Polygon notarization via the shared relayer.
///
/// Obtains the owner signature (EIP-191) from [WalletService], then
/// delegates to [VaultBlockchainHandler] which invokes the `anchor-relay`
/// Edge Function for live Polygon mainnet broadcast.
class PolygonChainNotarizer implements ChainNotarizer {
  PolygonChainNotarizer({
    WalletService? walletService,
    VaultBlockchainHandler? blockchainHandler,
  })  : _walletService = walletService ?? getIt<WalletService>(),
        _blockchainHandler = blockchainHandler ??
            getIt<VaultBlockchainHandler>();

  final WalletService _walletService;
  final VaultBlockchainHandler _blockchainHandler;

  @override
  Future<String> notarizeFileHash({
    required String fileHash,
    required String deviceSignature,
  }) async {
    // Obtain the EIP-191 owner signature for the relay's auth check
    final ownerSignature = await _walletService.signMessageHash(fileHash);

    return _blockchainHandler.notarizeFileHash(
      fileHash: fileHash,
      ownerSignature: ownerSignature,
      deviceSignature: deviceSignature,
    );
  }
}
