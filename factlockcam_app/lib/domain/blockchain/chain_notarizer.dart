import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/locator.dart';
import '../../data/supabase/seal_ledger_repository.dart';

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

class PolygonChainNotarizer implements ChainNotarizer {
  @override
  Future<String> notarizeFileHash({
    required String fileHash,
    required String deviceSignature,
  }) {
    throw UnsupportedError(
      'Polygon notarization is not wired yet. Keep USE_POLYGON_NOTARIZER=false '
      'until the on-chain adapter is implemented.',
    );
  }
}
