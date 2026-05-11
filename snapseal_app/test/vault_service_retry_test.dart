import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:postgrest/postgrest.dart';
import 'package:snapseal/core/crypto/vault_encryption_handler.dart';
import 'package:snapseal/core/ghost_key/native_enclave_channel.dart';
import 'package:snapseal/data/local/vault_database.dart';
import 'package:snapseal/data/models/archive_item.dart';
import 'package:snapseal/data/services/local_vault_storage.dart';
import 'package:snapseal/data/supabase/auth_repository.dart';
import 'package:snapseal/data/supabase/seal_ledger_repository.dart';
import 'package:snapseal/domain/blockchain/chain_notarizer.dart';
import 'package:snapseal/domain/services/vault_service.dart';

class _MockVaultDatabase extends Mock implements VaultDatabase {}

class _MockLocalVaultStorage extends Mock implements LocalVaultStorage {}

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

class _MockVaultEncryption extends Mock implements VaultEncryptionHandler {}

class _MockSealLedgerRepository extends Mock implements SealLedgerRepository {}

class _MockChainNotarizer extends Mock implements ChainNotarizer {}

class _MockNativeEnclaveChannel extends Mock implements NativeEnclaveChannel {}

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockVaultDatabase database;
  late _MockLocalVaultStorage storage;
  late _MockSecureStorage secureStorage;
  late _MockVaultEncryption vaultEncryption;
  late _MockSealLedgerRepository ledger;
  late _MockChainNotarizer chain;
  late _MockNativeEnclaveChannel native;
  late _MockAuthRepository auth;
  late VaultService service;

  const assetFingerprint = 'abc123';
  final item = ArchiveItem(
    assetFingerprint: assetFingerprint,
    encryptedPath: '/tmp/a.seal',
    thumbnailPath: '/tmp/a.jpg',
    byteLength: 1,
    createdAt: DateTime.utc(2026, 5, 11),
    pendingSync: true,
    syncAttemptCount: 0,
  );

  setUp(() {
    database = _MockVaultDatabase();
    storage = _MockLocalVaultStorage();
    secureStorage = _MockSecureStorage();
    vaultEncryption = _MockVaultEncryption();
    ledger = _MockSealLedgerRepository();
    chain = _MockChainNotarizer();
    native = _MockNativeEnclaveChannel();
    auth = _MockAuthRepository();

    service = VaultService(
      database: database,
      storage: storage,
      secureStorage: secureStorage,
      vaultEncryption: vaultEncryption,
      sealLedgerRepository: ledger,
      chainNotarizer: chain,
      nativeEnclave: native,
      authRepository: auth,
    );

    when(() => database.findArchiveItem(assetFingerprint)).thenAnswer((_) async => item);
    when(() => ledger.isConfigured).thenReturn(true);
    when(() => auth.currentUserId).thenReturn('user-1');
    when(() => ledger.syncAssetFingerprint(assetFingerprint)).thenAnswer(
      (_) async => SealLedgerSyncStatus.synced,
    );
  });

  test('clears pending sync when proof status is owned_by_me', () async {
    when(() => ledger.checkProofStatus(assetFingerprint)).thenAnswer((_) async => 'owned_by_me');
    when(() => database.markSyncSucceeded(assetFingerprint: assetFingerprint))
        .thenAnswer((_) async {});

    final result = await service.retryPendingRemoteSync(assetFingerprint);

    expect(result, isTrue);
    verify(() => database.markSyncSucceeded(assetFingerprint: assetFingerprint)).called(1);
  });

  test('defers retry when chain notarization fails with recoverable error', () async {
    when(() => ledger.checkProofStatus(assetFingerprint)).thenAnswer((_) async => 'new');
    when(() => native.signHash(assetFingerprint)).thenAnswer((_) async => 'sig');
    when(() => chain.notarizeFileHash(fileHash: assetFingerprint, deviceSignature: 'sig'))
        .thenThrow(const SocketException('network down'));
    when(
      () => database.markSyncDeferred(
        assetFingerprint: assetFingerprint,
        nextRetryAt: any(named: 'nextRetryAt'),
      ),
    ).thenAnswer((_) async {});

    final result = await service.retryPendingRemoteSync(assetFingerprint);

    expect(result, isFalse);
    verify(
      () => database.markSyncDeferred(
        assetFingerprint: assetFingerprint,
        nextRetryAt: any(named: 'nextRetryAt'),
      ),
    ).called(1);
  });

  test('treats proof-ledger duplicate insert as successful idempotent sync', () async {
    when(() => ledger.checkProofStatus(assetFingerprint)).thenAnswer((_) async => 'new');
    when(() => native.signHash(assetFingerprint)).thenAnswer((_) async => 'sig');
    when(() => chain.notarizeFileHash(fileHash: assetFingerprint, deviceSignature: 'sig'))
        .thenAnswer((_) async => 'tx-hash');
    when(
      () => ledger.insertProofLedgerRow(
        assetHash: assetFingerprint,
        deviceSignature: 'sig',
        chainTxHash: 'tx-hash',
      ),
    ).thenThrow(
      const PostgrestException(
        message: 'duplicate key',
        code: '23505',
      ),
    );
    when(() => database.markSyncSucceeded(assetFingerprint: assetFingerprint))
        .thenAnswer((_) async {});

    final result = await service.retryPendingRemoteSync(assetFingerprint);

    expect(result, isTrue);
    verify(() => database.markSyncSucceeded(assetFingerprint: assetFingerprint)).called(1);
  });

  test('returns false when asset is missing or no longer pending', () async {
    when(() => database.findArchiveItem(assetFingerprint))
        .thenAnswer((_) async => item.copyWith(pendingSync: false));

    final result = await service.retryPendingRemoteSync(assetFingerprint);

    expect(result, isFalse);
    verifyNever(() => ledger.checkProofStatus(any()));
  });
}
