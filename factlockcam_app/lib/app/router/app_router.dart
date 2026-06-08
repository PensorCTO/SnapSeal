import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ui/controllers/auth_controller.dart';
import '../../ui/controllers/key_custody_provider.dart';
import '../../ui/mobile/archive_home_view.dart';
import '../../ui/mobile/logon_view.dart';
import '../../ui/mobile/settings/burn_account_view.dart';
import '../../ui/mobile/settings/restore_archive_view.dart';
import '../../ui/web/web_archive_gate_view.dart';

/// Keeps a single [GoRouter] instance while auth/custody changes trigger redirect.
class AppRouterRefreshNotifier extends ChangeNotifier {
  AppRouterRefreshNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, _) => notifyListeners());
    _ref.listen(keyCustodyProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final location = state.matchedLocation;
    final isArchiveGate = location == WebArchiveGateView.routePath;
    const courierRoutePath = '/courier';
    final isCourierRoute = location == courierRoutePath;

    // Archive subdomain web bundle: gate page only (courier decommissioned).
    if (kIsWeb) {
      if (isArchiveGate) {
        return null;
      }
      return WebArchiveGateView.routePath;
    }

    if (isCourierRoute) {
      return LogonView.routePath;
    }

    final authChange = _ref.read(authStateProvider).asData?.value;
    final session = authChange?.session;
    final isAuthenticated = session != null;
    final isOnLogon = location == LogonView.routePath;
    final isOnRestore = location == RestoreArchiveView.routePath;
    final isOnBurn = location == BurnAccountView.routePath;
    const cameraRoutePath = '/camera';
    final isCaptureRoute = location == cameraRoutePath;
    final isLegacyVaultHome =
        location == ArchiveHomeView.legacyVaultHomePath;
    final isLegacyVaultDashboard = location == '/vault-dashboard';

    if (isCaptureRoute ||
        isLegacyVaultHome ||
        isLegacyVaultDashboard) {
      return ArchiveHomeView.routePath;
    }

    final custody = _ref.read(keyCustodyProvider);
    final custodyPending = custody.isLoading ||
        custody.maybeWhen(
          data: (status) => status == KeyCustodyStatus.unknown,
          orElse: () => false,
        );
    final keysMissing = custody.maybeWhen(
      data: (status) => status == KeyCustodyStatus.keysMissing,
      orElse: () => false,
    );

    if (isAuthenticated && custodyPending && !isOnRestore) {
      return null;
    }

    if (isAuthenticated && keysMissing && !isOnRestore) {
      return RestoreArchiveView.routePath;
    }

    if (isAuthenticated && !keysMissing && isOnRestore) {
      return ArchiveHomeView.routePath;
    }

    if (isAuthenticated && isOnLogon) {
      return ArchiveHomeView.routePath;
    }

    if (!isAuthenticated && !isOnLogon) {
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
      GoRoute(
        path: WebArchiveGateView.routePath,
        redirect: (_, _) => kIsWeb ? null : LogonView.routePath,
        builder: (context, state) => const WebArchiveGateView(),
      ),
      GoRoute(
        path: LogonView.routePath,
        builder: (context, state) => const LogonView(),
      ),
      GoRoute(
        path: '/vault-dashboard',
        redirect: (_, _) => ArchiveHomeView.routePath,
      ),
      GoRoute(
        path: ArchiveHomeView.legacyVaultHomePath,
        redirect: (_, _) => ArchiveHomeView.routePath,
      ),
      GoRoute(
        path: ArchiveHomeView.routePath,
        builder: (context, state) => const ArchiveHomeView(),
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
        path: '/camera',
        redirect: (_, _) => ArchiveHomeView.routePath,
      ),
      GoRoute(
        path: '/courier',
        redirect: (_, _) =>
            kIsWeb ? WebArchiveGateView.routePath : LogonView.routePath,
      ),
    ],
  );
});
