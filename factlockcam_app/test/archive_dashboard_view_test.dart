import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:factlockcam/data/models/archive_item.dart';
import 'package:factlockcam/ui/controllers/dashboard_controller.dart';
import 'package:factlockcam/ui/mobile/archive_home_view.dart';
import 'package:factlockcam/ui/mobile/camera/camera_view.dart';

import 'test_dependencies.dart';

void main() {
  setUpAll(() async {
    await setupTestDependencies();
  });

  test('ArchiveHomeView hub route path', () {
    expect(ArchiveHomeView.routePath, '/archive');
    expect(ArchiveHomeView.legacyVaultHomePath, '/vault-home');
  });

  testWidgets('archive shell shows hub launcher by default', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardControllerProvider.overrideWith(
            _EmptyVaultDashboardController.new,
          ),
        ],
        child: const MaterialApp(home: ArchiveHomeView()),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('ARCHIVE'), findsOneWidget);
    expect(find.text('PICTURE'), findsOneWidget);
    expect(find.text('VIDEO'), findsOneWidget);
    expect(find.text('SECURE COMM'), findsNothing);
    expect(find.text('DISPATCH CONSOLE'), findsNothing);
    expect(find.text('NO SEALED ASSETS'), findsNothing);
    expect(find.byType(CameraView), findsNothing);
  });

  testWidgets('archive tile opens omni surface', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardControllerProvider.overrideWith(
            _EmptyVaultDashboardController.new,
          ),
        ],
        child: const MaterialApp(home: ArchiveHomeView()),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('ARCHIVE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('NO SEALED ASSETS'), findsOneWidget);
  });

  testWidgets('account tile opens account panel', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardControllerProvider.overrideWith(
            _EmptyVaultDashboardController.new,
          ),
        ],
        child: const MaterialApp(home: ArchiveHomeView()),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('ACCOUNT & SETTINGS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('TERMS OF SERVICE'), findsOneWidget);
    expect(find.text('PRIVACY POLICY'), findsOneWidget);
    expect(find.text('HELP & SUPPORT'), findsOneWidget);
    expect(find.text('APP WEB PAGE'), findsOneWidget);
    expect(find.text('USER GUIDE'), findsOneWidget);
    expect(find.text('KEY CUSTODY & LIMITS'), findsOneWidget);
    expect(find.text('BURN ACCOUNT'), findsOneWidget);
    expect(find.text('LOG OUT'), findsOneWidget);
  });

  testWidgets('account back returns to hub', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardControllerProvider.overrideWith(
            _EmptyVaultDashboardController.new,
          ),
        ],
        child: const MaterialApp(home: ArchiveHomeView()),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('ACCOUNT & SETTINGS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byType(CupertinoNavigationBarBackButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('ARCHIVE'), findsOneWidget);
    expect(find.text('SECURE COMM'), findsNothing);
  });

  testWidgets('shows pending sync banner on hub', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardControllerProvider.overrideWith(
            _PendingArchiveDashboardController.new,
          ),
        ],
        child: const MaterialApp(home: ArchiveHomeView()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('pending sync'), findsOneWidget);
    expect(find.text('RETRY NOW'), findsOneWidget);

    await tester.pump(const Duration(seconds: 11));
  });
}

class _EmptyVaultDashboardController extends DashboardController {
  @override
  Future<List<ArchiveItem>> build() async => const [];

  @override
  Future<void> syncPendingInBackground() async {}
}

class _PendingArchiveDashboardController extends DashboardController {
  @override
  Future<List<ArchiveItem>> build() async => [
    ArchiveItem(
      assetFingerprint: 'abc123456789pending',
      encryptedPath: '/tmp/fake.seal',
      thumbnailPath: '/tmp/fake.jpg',
      byteLength: 42,
      createdAt: DateTime.utc(2026, 5, 10),
      mimeType: 'image/jpeg',
      pendingSync: true,
    ),
  ];

  @override
  Future<void> syncPendingInBackground() async {}
}
