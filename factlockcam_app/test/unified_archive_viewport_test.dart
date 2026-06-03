import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:factlockcam/data/models/archive_item.dart';
import 'package:factlockcam/domain/services/notarization_monitor_service.dart';
import 'package:factlockcam/ui/controllers/dashboard_controller.dart';
import 'package:factlockcam/ui/mobile/archive/archive_omni/unified_archive_viewport.dart';
import 'package:factlockcam/ui/mobile/archive/chronology_card.dart';
import 'package:factlockcam/ui/mobile/archive/providers/thumbnail_cache_provider.dart';

import 'helpers/layout_test_helpers.dart';
import 'test_dependencies.dart';

void main() {
  setUpAll(() async {
    await setupTestDependencies();
  });

  Future<void> pumpChronologyViewport(
    WidgetTester tester, {
    required Size surface,
  }) async {
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardControllerProvider.overrideWith(
            _SampleArchiveDashboardController.new,
          ),
          thumbnailCacheProvider.overrideWith(
            (ref, fingerprint) async => Uint8List(0),
          ),
          notarizationMonitorProvider.overrideWithValue(
            SimulatedNotarizationMonitorService(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: UnifiedArchiveViewport(),
          ),
        ),
      ),
    );
    await expectNoLayoutOverflow(tester);
  }

  testWidgets('chronology view renders archive cards with visible titles', (
    tester,
  ) async {
    await pumpChronologyViewport(tester, surface: const Size(390, 844));

    expect(find.text('NO SEALED ASSETS'), findsNothing);
    expect(find.byType(ChronologyCard), findsNWidgets(2));
    expect(find.text('Sunset capture'), findsOneWidget);
    expect(find.text('Morning clip'), findsOneWidget);
    expect(find.byType(Opacity), findsNothing);

    // Cards must occupy non-zero layout space (regression: invisible archive).
    for (final element in find.byType(ChronologyCard).evaluate()) {
      final box = element.renderObject! as RenderBox;
      expect(box.size.height, greaterThan(200));
      expect(box.hasSize, isTrue);
    }
  });

  testWidgets('chronology landscape avoids overflow with scaled cards', (
    tester,
  ) async {
    await pumpChronologyViewport(tester, surface: const Size(844, 390));

    expect(find.byType(ChronologyCard), findsAtLeastNWidgets(1));
    for (final element in find.byType(ChronologyCard).evaluate()) {
      final box = element.renderObject! as RenderBox;
      expect(box.size.height, greaterThan(120));
      expect(box.hasSize, isTrue);
    }
  });

  testWidgets('chronology compact phone landscape avoids overflow', (
    tester,
  ) async {
    await pumpChronologyViewport(tester, surface: const Size(932, 430));

    expect(find.byType(ChronologyCard), findsAtLeastNWidgets(1));
    expect(find.textContaining('Vault'), findsNothing);
  });
}

class _SampleArchiveDashboardController extends DashboardController {
  @override
  Future<List<ArchiveItem>> build() async => [
    ArchiveItem(
      assetFingerprint: 'fp_sunset_capture_001',
      encryptedPath: '/tmp/sunset.seal',
      thumbnailPath: '/tmp/sunset.jpg',
      byteLength: 2048,
      createdAt: DateTime.utc(2026, 5, 24, 14),
      mimeType: 'image/jpeg',
      title: 'Sunset capture',
    ),
    ArchiveItem(
      assetFingerprint: 'fp_morning_clip_002',
      encryptedPath: '/tmp/morning.seal',
      thumbnailPath: '/tmp/morning.jpg',
      byteLength: 4096,
      createdAt: DateTime.utc(2026, 5, 23, 9),
      mimeType: 'video/mp4',
      title: 'Morning clip',
    ),
  ];

  @override
  Future<void> syncPendingInBackground() async {}
}
