import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ui/controllers/auth_controller.dart';
import '../../ui/views/archive_view.dart';
import '../../ui/views/camera/acquisition_mode.dart';
import '../../ui/views/camera/camera_view.dart';
import '../../ui/views/logon_view.dart';
import '../../ui/views/vault_home_view.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final session = authState.asData?.value?.session;
      final isAuthenticated = session != null;
      final isOnLogon = state.matchedLocation == LogonView.routePath;

      if (isAuthenticated && isOnLogon) {
        return VaultHomeView.routePath;
      }

      if (!isAuthenticated && !isOnLogon) {
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
        path: ArchiveView.routePath,
        builder: (context, state) => const ArchiveView(),
      ),
      GoRoute(
        path: CameraView.routePath,
        builder: (context, state) {
          final mode = AcquisitionMode.parse(state.uri.queryParameters['mode']);
          return CameraView(mode: mode);
        },
      ),
    ],
  );
});
