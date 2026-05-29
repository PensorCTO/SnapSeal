import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ui/controllers/auth_controller.dart';
import '../../ui/controllers/key_custody_provider.dart';
import '../../ui/mobile/logon_view.dart';
import '../../ui/mobile/settings/burn_account_view.dart';
import '../../ui/mobile/settings/restore_archive_view.dart';
import '../../ui/mobile/vault_home_view.dart';
import '../../ui/web/courier_unlock_view.dart';

/// Keeps a single [GoRouter] instance while auth/custody changes trigger redirect.
class AppRouterRefreshNotifier extends ChangeNotifier {
  AppRouterRefreshNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, _) => notifyListeners());
    _ref.listen(keyCustodyProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final authChange = _ref.read(authStateProvider).asData?.value;
    final session = authChange?.session;
    final isAuthenticated = session != null;
    final location = state.matchedLocation;
    final isOnLogon = location == LogonView.routePath;
    final isCourierRoute = location == CourierUnlockView.routePath;
    final isOnRestore = location == RestoreArchiveView.routePath;
    final isOnBurn = location == BurnAccountView.routePath;

    final custody = _ref.read(keyCustodyProvider);
    final keysMissing = custody.maybeWhen(
      data: (status) => status == KeyCustodyStatus.keysMissing,
      orElse: () => false,
    );

    if (isAuthenticated && keysMissing && !isOnRestore) {
      return RestoreArchiveView.routePath;
    }

    if (isAuthenticated && !keysMissing && isOnRestore) {
      return VaultHomeView.routePath;
    }

    if (isAuthenticated && isOnLogon) {
      return VaultHomeView.routePath;
    }

    if (!isAuthenticated && !isOnLogon && !isCourierRoute) {
      return LogonView.routePath;
    }

    if (!isAuthenticated && (isOnRestore || isOnBurn)) {
      return LogonView.routePath;
    }

    return null;
  }
}

final appRouterRefreshNotifierProvider = Provider<AppRouterRefreshNotifier>(
  (ref) => AppRouterRefreshNotifier(ref),
);

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(appRouterRefreshNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: refreshNotifier.redirect,
    routes: [
      GoRoute(path: '/', redirect: (_, _) => LogonView.routePath),
      GoRoute(
        path: LogonView.routePath,
        builder: (context, state) => const LogonView(),
      ),
      GoRoute(
        path: '/vault-dashboard',
        redirect: (_, _) => VaultHomeView.routePath,
      ),
      GoRoute(
        path: VaultHomeView.routePath,
        builder: (context, state) => const VaultHomeView(),
      ),
      GoRoute(
        path: RestoreArchiveView.routePath,
        builder: (context, state) => const RestoreArchiveView(),
      ),
      GoRoute(
        path: BurnAccountView.routePath,
        builder: (context, state) => const BurnAccountView(),
      ),
      GoRoute(
        path: CourierUnlockView.routePath,
        builder: (context, state) =>
            CourierUnlockView(packageId: state.uri.queryParameters['pkg']),
      ),
    ],
  );
});
