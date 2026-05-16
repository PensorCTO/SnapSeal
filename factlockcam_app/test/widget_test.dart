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

  testWidgets('navigation tabs switch between vault home and camera views',
      (tester) async {
    final buildCounter = ValueNotifier<int>(0);

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

    // Home tab is selected by default — verify vault content is visible.
    expect(find.text('NO SEALED ASSETS'), findsOneWidget);
    expect(buildCounter.value, 1);

    // Tap Picture tab — camera view should appear.
    await tester.tap(find.text('PICTURE').last);
    await tester.pump(const Duration(milliseconds: 500));
    expect(buildCounter.value, 1);

    // Tap Video tab — video camera view should appear.
    await tester.tap(find.text('VIDEO').last);
    await tester.pump(const Duration(milliseconds: 500));
    expect(buildCounter.value, 1);

    // Tap Home tab — back to vault.
    await tester.tap(find.text('HOME'));
    await tester.pump(const Duration(milliseconds: 500));
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
