import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:snapseal/core/di/injection.dart';
import 'package:snapseal/data/models/archive_item.dart';
import 'package:snapseal/ui/controllers/dashboard_controller.dart';
import 'package:snapseal/ui/views/vault_dashboard_view.dart';

void main() {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await configureDependencies();
  });

  test('VaultDashboardView uses vault-first route path', () {
    expect(VaultDashboardView.routePath, '/vault-dashboard');
  });

  testWidgets('vault dashboard shows Vault shell when archive is empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardControllerProvider.overrideWith(
            _EmptyVaultDashboardController.new,
          ),
        ],
        child: const MaterialApp(home: VaultDashboardView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vault'), findsOneWidget);
    expect(find.text('Evidence vault'), findsOneWidget);
  });

  testWidgets(
    'tapping a thumbnail shows video and metadata actions',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardControllerProvider.overrideWith(
              _VideoArchiveDashboardController.new,
            ),
          ],
          child: const MaterialApp(home: VaultDashboardView()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();

      expect(find.text('Play video'), findsOneWidget);
      expect(find.text('Manage title and description'), findsOneWidget);
    },
  );
}

class _EmptyVaultDashboardController extends DashboardController {
  @override
  Future<List<ArchiveItem>> build() async => const [];

  @override
  Future<void> syncPendingInBackground() async {}
}

class _VideoArchiveDashboardController extends DashboardController {
  @override
  Future<List<ArchiveItem>> build() async => [
    ArchiveItem(
      assetFingerprint: 'abc123456789video',
      encryptedPath: '/tmp/fake.seal',
      thumbnailPath: '/tmp/fake.jpg',
      byteLength: 42,
      createdAt: DateTime.utc(2026, 5, 10),
      mimeType: 'video/mp4',
      pendingSync: false,
      title: 'Evidence clip',
      description: 'A short verification clip.',
    ),
  ];

  @override
  Future<void> syncPendingInBackground() async {}
}
