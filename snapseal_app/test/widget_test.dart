import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapseal/app/snapseal_app.dart';
import 'package:snapseal/data/models/archive_item.dart';
import 'package:snapseal/core/di/injection.dart';
import 'package:snapseal/ui/controllers/dashboard_controller.dart';
import 'package:snapseal/ui/views/camera/camera_view.dart';
import 'package:snapseal/ui/views/vault_dashboard_view.dart';

void main() {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await configureDependencies();
  });

  testWidgets('renders the SnapSeal logon shell', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SnapSealApp(),
      ),
    );

    expect(find.text('SnapSeal'), findsOneWidget);
    expect(find.text('Send Magic Number'), findsOneWidget);
    expect(find.text('Tamper-evident media vault'), findsOneWidget);
  });

  testWidgets(
    'does not refresh dashboard provider when camera is dismissed without capture',
    (tester) async {
      final buildCounter = ValueNotifier<int>(0);
      final router = GoRouter(
        initialLocation: VaultDashboardView.routePath,
        routes: [
          GoRoute(
            path: VaultDashboardView.routePath,
            builder: (context, state) => const VaultDashboardView(),
          ),
          GoRoute(
            path: CameraView.routePath,
            builder: (context, state) => const _DismissCameraView(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardControllerProvider.overrideWith(
              () => _CountingDashboardController(buildCounter),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(buildCounter.value, 1);

      await tester.tap(find.text('Photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dismiss camera'));
      await tester.pumpAndSettle();

      expect(buildCounter.value, 1);
    },
  );
}

class _CountingDashboardController extends DashboardController {
  _CountingDashboardController(this._buildCounter);

  final ValueNotifier<int> _buildCounter;

  @override
  Future<List<ArchiveItem>> build() async {
    _buildCounter.value += 1;
    return const [];
  }
}

class _DismissCameraView extends StatelessWidget {
  const _DismissCameraView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.pop(),
          child: const Text('Dismiss camera'),
        ),
      ),
    );
  }
}
