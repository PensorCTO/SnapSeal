import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/di/locator.dart';
import '../../core/ghost_key/key_custody_service.dart';
import '../../data/supabase/auth_repository.dart';
import '../../domain/blockchain/wallet_service.dart';
import '../../domain/services/vault_service.dart';
import '../../features/identity/presentation/providers/current_profile_provider.dart';

enum KeyCustodyStatus {
  unknown,
  keysPresent,
  keysMissing,
  notApplicable,
}

final keyCustodyProvider =
    AsyncNotifierProvider<KeyCustodyNotifier, KeyCustodyStatus>(
  KeyCustodyNotifier.new,
);

class KeyCustodyNotifier extends AsyncNotifier<KeyCustodyStatus> {
  @override
  Future<KeyCustodyStatus> build() async {
    ref.watch(authRepositoryProvider);
    ref.watch(currentProfileProvider);
    return _resolveStatus();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _resolveStatus());
  }

  Future<KeyCustodyStatus> _resolveStatus() async {
    if (kIsWeb || !AppConfig.usePolygonNotarizer) {
      return KeyCustodyStatus.notApplicable;
    }
    final session = ref.read(authRepositoryProvider).currentSession;
    if (session == null) {
      return KeyCustodyStatus.notApplicable;
    }

    final custody = getIt<KeyCustodyService>();
    if (await custody.hasLocalKeys()) {
      return KeyCustodyStatus.keysPresent;
    }

    final profile = ref.read(currentProfileProvider).asData?.value;
    final remoteWallet = profile?.activeWalletAddress?.trim();
    if (remoteWallet == null || remoteWallet.isEmpty) {
      await getIt<WalletService>().ensureEvmAddress();
      await getIt<VaultService>().ensureVaultKey();
      if (await custody.hasLocalKeys()) {
        return KeyCustodyStatus.keysPresent;
      }
    }

    return KeyCustodyStatus.keysMissing;
  }
}
