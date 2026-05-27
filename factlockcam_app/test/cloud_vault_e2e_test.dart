import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:factlockcam/application/vault/vault_sync_coordinator.dart';
import 'package:factlockcam/core/cloud/supabase_vault_service.dart';
import 'package:factlockcam/core/crypto/vault_encryption_handler.dart';
import 'package:factlockcam/core/platform/platform_channel_coordinator.dart';
import 'package:factlockcam/data/supabase/seal_ledger_repository.dart';

class _MockSealLedgerRepository extends Mock implements SealLedgerRepository {}

class _MockSupabaseVaultService extends Mock implements SupabaseVaultService {}

class _FakePlatformCoordinator extends Fake
    implements IPlatformChannelCoordinator {
  @override
  Future<T> executeWithBackgroundScope<T>(
    Future<T> Function() criticalUploadTask,
  ) {
    return criticalUploadTask();
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  late _MockSealLedgerRepository sealLedger;
  late _MockSupabaseVaultService vaultService;
  late _FakePlatformCoordinator platformCoordinator;
  late VaultSyncCoordinator coordinator;
  late DefaultVaultEncryptionHandler vault;

  const packageId = '11111111-1111-1111-1111-111111111111';
  const assetHash = 'deadbeef';
  const userId = '22222222-2222-2222-2222-222222222222';
  const encodedKey = 'dGVzdC1rZXktbWF0ZXJpYWw=';
  const cloudPassword = encodedKey;

  setUp(() {
    sealLedger = _MockSealLedgerRepository();
    vaultService = _MockSupabaseVaultService();
    platformCoordinator = _FakePlatformCoordinator();
    vault = DefaultVaultEncryptionHandler();

    when(() => sealLedger.isConfigured).thenReturn(true);
    when(
      () => sealLedger.getOrCreateCourierPackage(
        assetHash: any(named: 'assetHash'),
        verifierPassword: any(named: 'verifierPassword'),
        encodedVaultKey: any(named: 'encodedVaultKey'),
        fileExtension: any(named: 'fileExtension'),
        storagePath: any(named: 'storagePath'),
      ),
    ).thenAnswer((_) async => packageId);

    when(
      () => vaultService.uploadEncryptedAsset(
        encryptedBytes: any(named: 'encryptedBytes'),
        packageId: any(named: 'packageId'),
        storagePath: any(named: 'storagePath'),
        plaintextFileSizeBytes: any(named: 'plaintextFileSizeBytes'),
      ),
    ).thenAnswer((_) async => '$userId/$packageId.enc');

    coordinator = VaultSyncCoordinator(
      sealLedgerRepository: sealLedger,
      vaultService: vaultService,
      channelCoordinator: platformCoordinator,
    );
  });

  test('cloud vault pipeline encrypts in isolate and uploads ciphertext', () async {
    final tempDir = await Directory.systemTemp.createTemp('cloud_vault_e2e_');
    final rawFile = File('${tempDir.path}/capture.jpg');
    const plaintext = 'integration-test-capture-payload';
    await rawFile.writeAsBytes(Uint8List.fromList(plaintext.codeUnits));

    final outcome = await coordinator.syncAfterNotarization(
      rawSourceFile: rawFile,
      assetHash: assetHash,
      mimeType: 'image/jpeg',
      userId: userId,
      encodedVaultKey: encodedKey,
      cloudSealPassword: cloudPassword,
    );

    expect(outcome.uploaded, isTrue);
    expect(outcome.packageId, packageId);
    expect(outcome.storagePath, '$userId/$packageId.enc');

    final captured = verify(
      () => vaultService.uploadEncryptedAsset(
        encryptedBytes: captureAny(named: 'encryptedBytes'),
        packageId: packageId,
        storagePath: '$userId/$packageId.enc',
        plaintextFileSizeBytes: plaintext.length,
      ),
    ).captured;

    final encryptedBytes = captured.first as Uint8List;
    expect(encryptedBytes, isNotEmpty);
    expect(encryptedBytes.length, greaterThan(plaintext.length));

    final decrypted = await vault.decrypt(
      encryptedPayload: encryptedBytes,
      keyBytes: Uint8List.fromList(
        crypto.sha256.convert(utf8.encode(cloudPassword)).bytes,
      ),
    );
    expect(String.fromCharCodes(decrypted), plaintext);

    await tempDir.delete(recursive: true);
  });
}
