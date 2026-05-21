import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:factlockcam/data/models/archive_item.dart';
import 'package:factlockcam/data/models/sealed_asset.dart';
import 'package:factlockcam/domain/services/vault_service.dart';
import 'package:factlockcam/ui/mobile/archive_photo_view.dart';

class _MockVaultService extends Mock implements VaultService {}

void main() {
  testWidgets('ArchivePhotoView does not decrypt again on rebuild', (
    tester,
  ) async {
    final vault = _MockVaultService();
    var extractCount = 0;
    const assetFingerprint = 'abc123456789photo';
    final item = ArchiveItem(
      assetFingerprint: assetFingerprint,
      encryptedPath: '/tmp/fake.seal',
      thumbnailPath: '/tmp/fake.jpg',
      byteLength: 1,
      createdAt: DateTime.utc(2026, 5, 12),
      mimeType: 'image/png',
    );

    when(() => vault.extractForCourier(assetFingerprint)).thenAnswer((_) async {
      extractCount += 1;
      return SealedAsset(
        assetFingerprint: assetFingerprint,
        bytes: Uint8List.fromList(_transparentPngBytes),
      );
    });

    final widget = ProviderScope(
      overrides: [vaultServiceProvider.overrideWithValue(vault)],
      child: MaterialApp(home: ArchivePhotoView(item: item)),
    );

    await tester.pumpWidget(widget);
    await tester.pump();
    await tester.pumpWidget(widget);
    await tester.pump();

    expect(extractCount, 1);
  });
}

const _transparentPngBytes = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];
