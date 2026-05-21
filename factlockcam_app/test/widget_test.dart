import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:factlockcam/app/factlockcam_app.dart';
import 'package:factlockcam/core/di/injection.dart';
import 'package:factlockcam/data/models/archive_item.dart';
import 'package:factlockcam/ui/controllers/dashboard_controller.dart';
import 'package:factlockcam/ui/mobile/vault_home_view.dart';

void main() {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await configureDependencies();
  });

  testWidgets('renders the FactLockCam logon shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FactLockCamApp()));

    expect(find.text('FACTLOCKCAM'), findsOneWidget);
    expect(find.text('SEND MAGIC NUMBER'), findsOneWidget);
    expect(find.text('TAMPER-EVIDENT MEDIA VAULT'), findsOneWidget);
  });

  testWidgets('hub tiles switch between vault home and camera views',
      (tester) async {
    final buildCounter = ValueNotifier<int>(0);

    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardControllerProvider.overrideWith(
            () => _CountingDashboardController(buildCounter),
          ),
        ],
        child: const MaterialApp(home: VaultHomeView()),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('CHOOSE AN ACTION'), findsNothing);
    expect(find.text('VAULT'), findsOneWidget);
    expect(buildCounter.value, 1);

    final pictureTile = find.text('PICTURE');
    await tester.ensureVisible(pictureTile);
    await tester.tap(pictureTile);
    await tester.pump(const Duration(milliseconds: 500));
    expect(buildCounter.value, 1);
    expect(find.byType(CupertinoNavigationBarBackButton), findsOneWidget);

    await tester.tap(find.byType(CupertinoNavigationBarBackButton));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('VAULT'), findsOneWidget);
    expect(buildCounter.value, 1);
  });
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
