import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:factlockcam/data/models/archive_item.dart';
import 'package:factlockcam/ui/controllers/dashboard_controller.dart';
import 'package:factlockcam/ui/mobile/archive_home_view.dart';

import 'test_dependencies.dart';

void main() {
  setUpAll(() async {
    await setupTestDependencies();
  });

  test('ArchiveHomeView hub route path', () {
    expect(ArchiveHomeView.routePath, '/archive');
    expect(ArchiveHomeView.legacyVaultHomePath, '/vault-home');
  });

  testWidgets('archive hub shows four action tiles without instructional copy', (
    tester,
  ) async {
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

    expect(find.text('CHOOSE AN ACTION'), findsNothing);
    expect(find.text('ARCHIVE'), findsOneWidget);
    expect(find.text('PICTURE'), findsWidgets);
    expect(find.text('VIDEO'), findsWidgets);
    expect(find.text('ACCOUNT & SETTINGS'), findsOneWidget);
  });

  testWidgets('archive hub renders a Stack-based heavy-metal layout', (
    tester,
  ) async {
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

    final stacks = find.descendant(
      of: find.byType(ArchiveHomeView),
      matching: find.byType(Stack),
    );
    expect(stacks, findsWidgets);
  });

  testWidgets('account tile opens account settings panel', (tester) async {
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

    final accountTile = find.text('ACCOUNT & SETTINGS');
    await tester.ensureVisible(accountTile);
    await tester.tap(accountTile);
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
    expect(
      find.textContaining('You hold the only keys that decrypt'),
      findsNothing,
    );
  });

  testWidgets('shows pending sync banner and retry on archive hub', (
    tester,
  ) async {
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
