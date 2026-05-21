import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ui/controllers/auth_controller.dart';
import '../../ui/mobile/logon_view.dart';
import '../../ui/mobile/vault_home_view.dart';
import '../../ui/web/courier_unlock_view.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final session = authState.asData?.value?.session;
      final isAuthenticated = session != null;
      final isOnLogon = state.matchedLocation == LogonView.routePath;
      final isCourierRoute =
          state.matchedLocation == CourierUnlockView.routePath;

      if (isAuthenticated && isOnLogon) {
        return VaultHomeView.routePath;
      }

      if (!isAuthenticated && !isOnLogon && !isCourierRoute) {
        return LogonView.routePath;
      }

      return null;
    },
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
        path: CourierUnlockView.routePath,
        builder: (context, state) =>
            CourierUnlockView(packageId: state.uri.queryParameters['pkg']),
      ),
    ],
  );
});
