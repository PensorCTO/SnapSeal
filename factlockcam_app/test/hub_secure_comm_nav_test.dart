import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:factlockcam/data/models/archive_item.dart';
import 'package:factlockcam/ui/controllers/dashboard_controller.dart';
import 'package:factlockcam/ui/mobile/archive_home_view.dart';
import 'package:factlockcam/ui/mobile/camera/camera_view.dart';
import 'package:factlockcam/ui/mobile/secure_comm_capture_view.dart';

import 'test_dependencies.dart';

void main() {
  setUpAll(() async {
    await setupTestDependencies();
  });

  testWidgets('hub landing shows five tiles without bottom dispatch tab', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardControllerProvider.overrideWith(
            _EmptyArchiveDashboardController.new,
          ),
        ],
        child: const MaterialApp(home: ArchiveHomeView()),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('ARCHIVE'), findsOneWidget);
    expect(find.text('PICTURE'), findsOneWidget);
    expect(find.text('VIDEO'), findsOneWidget);
    expect(find.text('ACCOUNT & SETTINGS'), findsOneWidget);
    expect(find.text('SECURE COMM'), findsOneWidget);
    expect(find.text('DISPATCH CONSOLE'), findsNothing);
    expect(find.text('CAPTURE'), findsNothing);
    expect(find.byType(CameraView), findsNothing);
  });

  testWidgets('secure comm tile opens zero-click capture view', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardControllerProvider.overrideWith(
            _EmptyArchiveDashboardController.new,
          ),
        ],
        child: const MaterialApp(home: ArchiveHomeView()),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('SECURE COMM'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SecureCommCaptureView), findsOneWidget);
    expect(find.text('SELECT ARCHIVE ITEM'), findsNothing);
    expect(find.text('CONTINUE'), findsNothing);
  });

  testWidgets('picture tile lazy-mounts camera', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardControllerProvider.overrideWith(
            _EmptyArchiveDashboardController.new,
          ),
        ],
        child: const MaterialApp(home: ArchiveHomeView()),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(CameraView), findsNothing);

    final pictureTile = find.text('PICTURE');
    await tester.ensureVisible(pictureTile);
    await tester.tap(pictureTile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(CameraView), findsOneWidget);
  });
}

class _EmptyArchiveDashboardController extends DashboardController {
  @override
  Future<List<ArchiveItem>> build() async => [];

  @override
  Future<void> syncPendingInBackground() async {}
}
