import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:snapseal/core/di/injection.dart';
import 'package:snapseal/data/models/archive_item.dart';
import 'package:snapseal/ui/controllers/dashboard_controller.dart';
import 'package:snapseal/ui/views/archive_view.dart';
import 'package:snapseal/ui/views/vault_home_view.dart';

void main() {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await configureDependencies();
  });

  test('VaultHomeView hub route path', () {
    expect(VaultHomeView.routePath, '/vault-home');
  });

  test('ArchiveView route path', () {
    expect(ArchiveView.routePath, '/archive');
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
    await tester.pumpAndSettle();

    expect(find.text('SnapSeal'), findsOneWidget);
    expect(find.text('Archive'), findsOneWidget);
    expect(find.text('Picture'), findsOneWidget);
    expect(find.text('Video'), findsOneWidget);
  });

  testWidgets('archive view shows Photos and Videos tabs', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardControllerProvider.overrideWith(
            _EmptyVaultDashboardController.new,
          ),
        ],
        child: const MaterialApp(home: ArchiveView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Photos'), findsOneWidget);
    expect(find.text('Videos'), findsOneWidget);
  });

  testWidgets(
    'tapping a video tile in Videos tab shows play and metadata actions',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardControllerProvider.overrideWith(
              _VideoArchiveDashboardController.new,
            ),
          ],
          child: const MaterialApp(home: ArchiveView()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Videos'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();

      expect(find.text('Play video'), findsOneWidget);
      expect(find.text('Manage title and description'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping a photo tile shows full-size photo and metadata actions',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardControllerProvider.overrideWith(
              _PhotoArchiveDashboardController.new,
            ),
          ],
          child: const MaterialApp(home: ArchiveView()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();

      expect(find.text('View full-size photo'), findsOneWidget);
      expect(find.text('Manage title and description'), findsOneWidget);
    },
  );

  testWidgets('shows pending sync banner and retry on archive', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardControllerProvider.overrideWith(
            _PendingArchiveDashboardController.new,
          ),
        ],
        child: const MaterialApp(home: ArchiveView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('pending sync'), findsOneWidget);
    expect(find.text('Retry now'), findsOneWidget);
  });
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

class _PhotoArchiveDashboardController extends DashboardController {
  @override
  Future<List<ArchiveItem>> build() async => [
    ArchiveItem(
      assetFingerprint: 'abc123456789photo',
      encryptedPath: '/tmp/fake.seal',
      thumbnailPath: '/tmp/fake.jpg',
      byteLength: 42,
      createdAt: DateTime.utc(2026, 5, 10),
      mimeType: 'image/jpeg',
      pendingSync: false,
      title: 'Evidence photo',
      description: 'A still verification image.',
    ),
  ];

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
