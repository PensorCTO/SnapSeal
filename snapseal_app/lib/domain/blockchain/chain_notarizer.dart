import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/supabase/seal_ledger_repository.dart';

/// Durable chain write path. Production: Polygon; today: Supabase-simulated ledger.
abstract class ChainNotarizer {
  Future<String> notarizeFileHash({
    required String fileHash,
    required String deviceSignature,
  });
}

final chainNotarizerProvider = Provider<ChainNotarizer>(
  (ref) => SimulatedChainNotarizer(ref.watch(sealLedgerRepositoryProvider)),
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
