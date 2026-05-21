import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:postgrest/postgrest.dart';
import 'package:factlockcam/core/crypto/vault_encryption_handler.dart';
import 'package:factlockcam/core/ghost_key/native_enclave_channel.dart';
import 'package:factlockcam/data/local/vault_database.dart';
import 'package:factlockcam/data/models/archive_item.dart';
import 'package:factlockcam/data/services/local_vault_storage.dart';
import 'package:factlockcam/data/supabase/auth_repository.dart';
import 'package:factlockcam/data/supabase/seal_ledger_repository.dart';
import 'package:factlockcam/domain/blockchain/chain_notarizer.dart';
import 'package:factlockcam/domain/blockchain/vault_blockchain_handler.dart';
import 'package:factlockcam/domain/blockchain/wallet_service.dart';
import 'package:factlockcam/domain/services/proof_sync_notifier.dart';
import 'package:factlockcam/domain/services/vault_service.dart';

class _MockVaultDatabase extends Mock implements VaultDatabase {}

class _MockLocalVaultStorage extends Mock implements LocalVaultStorage {}

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

class _MockVaultEncryption extends Mock implements VaultEncryptionHandler {}

class _MockSealLedgerRepository extends Mock implements SealLedgerRepository {}

class _MockChainNotarizer extends Mock implements ChainNotarizer {}

class _MockWalletService extends Mock implements WalletService {}

class _MockBlockchainHandler extends Mock implements VaultBlockchainHandler {}

class _MockNativeEnclaveChannel extends Mock implements NativeEnclaveChannel {}

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockVaultDatabase database;
  late _MockLocalVaultStorage storage;
  late _MockSecureStorage secureStorage;
  late _MockVaultEncryption vaultEncryption;
  late _MockSealLedgerRepository ledger;
  late _MockChainNotarizer chain;
  late _MockWalletService wallet;
  late _MockBlockchainHandler blockchain;
  late ProofSyncNotifier proofSyncNotifier;
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

  setUpAll(() {
    registerFallbackValue(
      ArchiveItem(
        assetFingerprint: 'fallback',
        encryptedPath: '/tmp/fallback.seal',
        thumbnailPath: '/tmp/fallback.jpg',
        byteLength: 0,
        createdAt: DateTime.utc(2026, 5, 11),
        pendingSync: true,
      ),
    );
  });

  setUp(() {
    database = _MockVaultDatabase();
    storage = _MockLocalVaultStorage();
    secureStorage = _MockSecureStorage();
    vaultEncryption = _MockVaultEncryption();
    ledger = _MockSealLedgerRepository();
    chain = _MockChainNotarizer();
    wallet = _MockWalletService();
    blockchain = _MockBlockchainHandler();
    proofSyncNotifier = ProofSyncNotifier();
    native = _MockNativeEnclaveChannel();
    auth = _MockAuthRepository();

    service = VaultService(
      database: database,
      storage: storage,
      secureStorage: secureStorage,
      vaultEncryption: vaultEncryption,
      sealLedgerRepository: ledger,
      chainNotarizer: chain,
      walletService: wallet,
      blockchainHandler: blockchain,
      proofSyncNotifier: proofSyncNotifier,
      nativeEnclave: native,
      authRepository: auth,
    );

    when(
      () => database.findArchiveItem(assetFingerprint),
    ).thenAnswer((_) async => item);
    when(() => ledger.isConfigured).thenReturn(true);
    when(() => auth.currentUserId).thenReturn('user-1');
    when(
      () => ledger.syncAssetFingerprint(assetFingerprint),
    ).thenAnswer((_) async => SealLedgerSyncStatus.synced);
  });

  test('clears pending sync when proof status is owned_by_me', () async {
    when(
      () => ledger.checkProofStatus(assetFingerprint),
    ).thenAnswer((_) async => 'owned_by_me');
    when(
      () => database.markSyncSucceeded(assetFingerprint: assetFingerprint),
    ).thenAnswer((_) async {});

    final result = await service.retryPendingRemoteSync(assetFingerprint);

    expect(result, isTrue);
    verify(
      () => database.markSyncSucceeded(assetFingerprint: assetFingerprint),
    ).called(1);
  });

  test(
    'proofLockFile marks capture pending when native signing has recoverable error',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'factlockcam_retry_test_',
      );
      final source = File('${tempDir.path}/capture.jpg');
      final rawBytes = Uint8List.fromList([1, 2, 3, 4]);
      final assetHash = crypto.sha256.convert(rawBytes).toString();
      final keyBytes = Uint8List.fromList(List<int>.filled(32, 1));
      final encryptedBytes = Uint8List.fromList([9, 8, 7]);
      final thumbnailBytes = Uint8List.fromList([6, 5, 4]);

      try {
        await source.writeAsBytes(rawBytes, flush: true);
        when(
          () => ledger.checkProofStatus(assetHash),
        ).thenAnswer((_) async => 'new');
        when(
          () => native.signHash(assetHash),
        ).thenThrow(const SocketException('connection reset'));
        when(
          () => secureStorage.read(key: any(named: 'key')),
        ).thenAnswer((_) async => null);
        when(() => vaultEncryption.generateKeyBytes()).thenReturn(keyBytes);
        when(() => vaultEncryption.encodeKey(keyBytes)).thenReturn('encoded');
        when(
          () => secureStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenAnswer((_) async {});
        when(
          () => vaultEncryption.encrypt(bytes: rawBytes, keyBytes: keyBytes),
        ).thenAnswer((_) async => encryptedBytes);
        when(
          () => vaultEncryption.generateThumbnail(rawBytes),
        ).thenAnswer((_) async => thumbnailBytes);
        when(
          () => storage.writeEncryptedOriginal(
            assetFingerprint: assetHash,
            bytes: encryptedBytes,
          ),
        ).thenAnswer((_) async => '/tmp/$assetHash.seal');
        when(
          () => storage.writeThumbnail(
            assetFingerprint: assetHash,
            bytes: thumbnailBytes,
          ),
        ).thenAnswer((_) async => '/tmp/$assetHash.jpg');
        when(() => database.upsertArchiveItem(any())).thenAnswer((_) async {});
        when(
          () => database.setPendingSync(
            assetFingerprint: assetHash,
            pendingSync: true,
          ),
        ).thenAnswer((_) async {});

        final result = await service.proofLockFile(source, 'user-1');

        expect(result.assetFingerprint, assetHash);
        expect(result.pendingSync, isTrue);
        expect(result.chainTxHash, isNull);
        verify(
          () => database.setPendingSync(
            assetFingerprint: assetHash,
            pendingSync: true,
          ),
        ).called(1);
        verifyNever(
          () => chain.notarizeFileHash(
            fileHash: any(named: 'fileHash'),
            deviceSignature: any(named: 'deviceSignature'),
          ),
        );
        verifyNever(
          () => ledger.insertProofLedgerRow(
            assetHash: any(named: 'assetHash'),
            deviceSignature: any(named: 'deviceSignature'),
            chainTxHash: any(named: 'chainTxHash'),
          ),
        );
      } finally {
        if (tempDir.existsSync()) {
          await tempDir.delete(recursive: true);
        }
      }
    },
  );

  test(
    'clears pending sync when proof status is anonymous (orphaned ledger wallet)',
    () async {
      when(
        () => ledger.checkProofStatus(assetFingerprint),
      ).thenAnswer((_) async => 'anonymous');
      when(
        () => database.markSyncSucceeded(assetFingerprint: assetFingerprint),
      ).thenAnswer((_) async {});

      final result = await service.retryPendingRemoteSync(assetFingerprint);

      expect(result, isTrue);
      verify(
        () => database.markSyncSucceeded(assetFingerprint: assetFingerprint),
      ).called(1);
      verifyNever(() => native.signHash(any()));
      verifyNever(
        () => chain.notarizeFileHash(
          fileHash: any(named: 'fileHash'),
          deviceSignature: any(named: 'deviceSignature'),
        ),
      );
      verifyNever(
        () => ledger.insertProofLedgerRow(
          assetHash: any(named: 'assetHash'),
          deviceSignature: any(named: 'deviceSignature'),
          chainTxHash: any(named: 'chainTxHash'),
        ),
      );
    },
  );

  test(
    'defers retry when chain notarization fails with recoverable error',
    () async {
      when(
        () => ledger.checkProofStatus(assetFingerprint),
      ).thenAnswer((_) async => 'new');
      when(
        () => native.signHash(assetFingerprint),
      ).thenAnswer((_) async => 'sig');
      when(
        () => chain.notarizeFileHash(
          fileHash: assetFingerprint,
          deviceSignature: 'sig',
        ),
      ).thenThrow(const SocketException('network down'));
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
    },
  );

  test(
    'defers retry when native signHash fails with recoverable error',
    () async {
      when(
        () => ledger.checkProofStatus(assetFingerprint),
      ).thenAnswer((_) async => 'new');
      when(
        () => native.signHash(assetFingerprint),
      ).thenThrow(const SocketException('failed'));
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
      verifyNever(
        () => chain.notarizeFileHash(
          fileHash: any(named: 'fileHash'),
          deviceSignature: any(named: 'deviceSignature'),
        ),
      );
    },
  );

  test(
    'returns false without throwing when signHash fails with non-recoverable error',
    () async {
      when(
        () => ledger.checkProofStatus(assetFingerprint),
      ).thenAnswer((_) async => 'new');
      when(
        () => native.signHash(assetFingerprint),
      ).thenThrow(const FormatException('bad enclave'));

      final result = await service.retryPendingRemoteSync(assetFingerprint);

      expect(result, isFalse);
      verifyNever(
        () => database.markSyncDeferred(
          assetFingerprint: any(named: 'assetFingerprint'),
          nextRetryAt: any(named: 'nextRetryAt'),
        ),
      );
    },
  );

  test(
    'nextRetryAt matches post-increment sync_attempt_count (exponential backoff)',
    () async {
      final postponedItem = ArchiveItem(
        assetFingerprint: assetFingerprint,
        encryptedPath: '/tmp/a.seal',
        thumbnailPath: '/tmp/a.jpg',
        byteLength: 1,
        createdAt: DateTime.utc(2026, 5, 11),
        pendingSync: true,
        syncAttemptCount: 2,
      );
      when(
        () => database.findArchiveItem(assetFingerprint),
      ).thenAnswer((_) async => postponedItem);
      when(
        () => ledger.checkProofStatus(assetFingerprint),
      ).thenAnswer((_) async => 'new');
      when(
        () => native.signHash(assetFingerprint),
      ).thenAnswer((_) async => 'sig');
      when(
        () => chain.notarizeFileHash(
          fileHash: assetFingerprint,
          deviceSignature: 'sig',
        ),
      ).thenThrow(const SocketException('network down'));

      DateTime? capturedNextRetry;
      when(
        () => database.markSyncDeferred(
          assetFingerprint: assetFingerprint,
          nextRetryAt: any(named: 'nextRetryAt'),
        ),
      ).thenAnswer((invocation) async {
        capturedNextRetry =
            invocation.namedArguments[#nextRetryAt]! as DateTime;
      });

      await service.retryPendingRemoteSync(assetFingerprint);

      // Count becomes 3 in DB; backoff minutes = 2^3 = 8.
      final delta = capturedNextRetry!
          .difference(DateTime.now().toUtc())
          .inMinutes;
      expect(delta, closeTo(8, 1));
    },
  );

  test(
    'treats proof-ledger duplicate insert as successful idempotent sync',
    () async {
      when(
        () => ledger.checkProofStatus(assetFingerprint),
      ).thenAnswer((_) async => 'new');
      when(
        () => native.signHash(assetFingerprint),
      ).thenAnswer((_) async => 'sig');
      when(
        () => chain.notarizeFileHash(
          fileHash: assetFingerprint,
          deviceSignature: 'sig',
        ),
      ).thenAnswer((_) async => 'tx-hash');
      when(
        () => ledger.insertProofLedgerRow(
          assetHash: assetFingerprint,
          deviceSignature: 'sig',
          chainTxHash: 'tx-hash',
        ),
      ).thenThrow(
        const PostgrestException(message: 'duplicate key', code: '23505'),
      );
      when(
        () => database.markSyncSucceeded(assetFingerprint: assetFingerprint),
      ).thenAnswer((_) async {});

      final result = await service.retryPendingRemoteSync(assetFingerprint);

      expect(result, isTrue);
      verify(
        () => database.markSyncSucceeded(assetFingerprint: assetFingerprint),
      ).called(1);
    },
  );

  test('returns false when asset is missing or no longer pending', () async {
    when(
      () => database.findArchiveItem(assetFingerprint),
    ).thenAnswer((_) async => item.copyWith(pendingSync: false));

    final result = await service.retryPendingRemoteSync(assetFingerprint);

    expect(result, isFalse);
    verifyNever(() => ledger.checkProofStatus(any()));
  });
}
