import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:factlockcam/data/models/archive_item.dart';
import 'package:factlockcam/ui/mobile/archive/archive_presentation_copy.dart';
import 'package:factlockcam/ui/mobile/archive/asset_inspector_screen.dart';
import 'package:factlockcam/ui/mobile/archive/providers/asset_metadata_provider.dart';
import 'package:factlockcam/ui/mobile/archive/providers/thumbnail_cache_provider.dart';

import 'helpers/layout_test_helpers.dart';
import 'test_dependencies.dart';

void main() {
  setUpAll(() async {
    await setupTestDependencies();
  });

  final sampleItem = ArchiveItem(
    assetFingerprint: 'fp_inspector_layout_001',
    encryptedPath: '/tmp/sample.seal',
    thumbnailPath: '/tmp/sample.jpg',
    byteLength: 2048,
    createdAt: DateTime.utc(2026, 6, 3, 12),
    mimeType: 'image/jpeg',
    title: 'Layout test asset',
  );

  Future<void> pumpInspector(
    WidgetTester tester, {
    required Size surface,
  }) async {
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          thumbnailCacheProvider.overrideWith(
            (ref, fingerprint) async => Uint8List(0),
          ),
        ],
        child: MaterialApp(
          home: AssetInspectorScreen(item: sampleItem),
        ),
      ),
    );
    await expectNoLayoutOverflow(tester);
  }

  testWidgets('inspector portrait layout has archive actions', (tester) async {
    await pumpInspector(tester, surface: const Size(390, 844));

    expect(find.text(ArchivePresentationCopy.inspectorSendProof), findsOneWidget);
    expect(find.text(ArchivePresentationCopy.inspectorBack), findsOneWidget);
    expect(find.textContaining('Vault'), findsNothing);
  });

  testWidgets('inspector landscape layout avoids overflow', (tester) async {
    await pumpInspector(tester, surface: const Size(844, 390));

    expect(find.text(ArchivePresentationCopy.inspectorViewPlay), findsOneWidget);
    expect(find.text(ArchivePresentationCopy.inspectorBack), findsOneWidget);
  });
}
