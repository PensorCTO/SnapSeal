import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:factlockcam/core/di/injection.dart';
import 'package:factlockcam/data/models/archive_item.dart';
import 'package:factlockcam/ui/controllers/dashboard_controller.dart';
import 'package:factlockcam/ui/mobile/vault_home_view.dart';

void main() {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await configureDependencies();
  });

  test('VaultHomeView hub route path', () {
    expect(VaultHomeView.routePath, '/vault-home');
  });

  testWidgets('vault hub shows Archive, Picture, and Video actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardControllerProvider.overrideWith(
            _EmptyVaultDashboardController.new,
          ),
        ],
        child: const MaterialApp(home: VaultHomeView()),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('FACTLOCKCAM'), findsOneWidget);
    expect(find.text('CHOOSE AN ACTION'), findsOneWidget);
    expect(find.text('VAULT'), findsOneWidget);
    expect(find.text('PICTURE'), findsWidgets);
    expect(find.text('VIDEO'), findsWidgets);
  });

  testWidgets('vault hub renders a Stack-based heavy-metal layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardControllerProvider.overrideWith(
            _EmptyVaultDashboardController.new,
          ),
        ],
        child: const MaterialApp(home: VaultHomeView()),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    final stacks = find.descendant(
      of: find.byType(VaultHomeView),
      matching: find.byType(Stack),
    );
    expect(stacks, findsWidgets);
    expect(find.text('CHOOSE AN ACTION'), findsOneWidget);
  });

  testWidgets('shows pending sync banner and retry on vault hub', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardControllerProvider.overrideWith(
            _PendingArchiveDashboardController.new,
          ),
        ],
        child: const MaterialApp(home: VaultHomeView()),
      ),
    );
    await tester.pumpAndSettle();

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
