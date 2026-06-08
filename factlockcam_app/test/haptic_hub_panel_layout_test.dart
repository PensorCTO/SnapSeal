import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:factlockcam/data/models/archive_item.dart';
import 'package:factlockcam/ui/controllers/dashboard_controller.dart';
import 'package:factlockcam/ui/mobile/archive/haptic_hub_panel.dart';

import 'helpers/layout_test_helpers.dart';
import 'test_dependencies.dart';

void main() {
  setUpAll(() async {
    await setupTestDependencies();
  });

  testWidgets('hub landscape uses compact grid without overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardControllerProvider.overrideWith(
            _EmptyArchiveDashboardController.new,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: HapticHubPanel(),
          ),
        ),
      ),
    );
    await expectNoLayoutOverflow(tester);

    expect(find.text('ARCHIVE'), findsOneWidget);
    expect(find.text('PICTURE'), findsOneWidget);
    expect(find.text('VIDEO'), findsOneWidget);
    expect(find.text('ACCOUNT & SETTINGS'), findsOneWidget);
    expect(find.text('SECURE COMM'), findsNothing);
  });
}

class _EmptyArchiveDashboardController extends DashboardController {
  @override
  Future<List<ArchiveItem>> build() async => [];

  @override
  Future<void> syncPendingInBackground() async {}
}
