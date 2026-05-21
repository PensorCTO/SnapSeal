import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/locator.dart';
import '../../../../data/supabase/seal_ledger_repository.dart';

class CurrentProfile {
  const CurrentProfile({this.activeWalletAddress});

  final String? activeWalletAddress;
}

final currentProfileProvider = FutureProvider<CurrentProfile>((ref) async {
  final repository = getIt<SealLedgerRepository>();
  if (!repository.isConfigured) {
    return const CurrentProfile();
  }
  final address = await repository.fetchActiveEvmAddress();
  return CurrentProfile(activeWalletAddress: address);
});
