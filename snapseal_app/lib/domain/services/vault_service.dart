import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:postgrest/postgrest.dart';

import '../../core/crypto/courier_crypto.dart';
import '../../core/crypto/vault_encryption_handler.dart';
import '../../core/di/locator.dart';
import '../../core/ghost_key/native_enclave_channel.dart';
import '../../data/local/vault_database.dart';
import '../../data/models/archive_item.dart';
import '../../data/models/sealed_asset.dart';
import '../../data/services/local_vault_storage.dart';
import '../../data/supabase/auth_repository.dart';
import '../../data/supabase/seal_ledger_repository.dart';
import '../blockchain/chain_notarizer.dart';

final vaultServiceProvider = Provider<VaultService>(
  (ref) => getIt<VaultService>(),
);

class ProofLockConflictException implements Exception {
  ProofLockConflictException(this.status);
  final String status;

  @override
  String toString() => 'Proof already exists on ledger (status=$status).';
}

class SealCaptureResult {
  const SealCaptureResult({
    required this.assetFingerprint,
    required this.pendingSync,
    this.chainTxHash,
  });

  final String assetFingerprint;
  final bool pendingSync;
  final String? chainTxHash;
}

class VaultService {
  VaultService({
    required VaultDatabase database,
    required LocalVaultStorage storage,
    required FlutterSecureStorage secureStorage,
    required VaultEncryptionHandler vaultEncryption,
    required SealLedgerRepository sealLedgerRepository,
    required ChainNotarizer chainNotarizer,
    required NativeEnclaveChannel nativeEnclave,
    required AuthRepository authRepository,
  }) : _database = database,
       _storage = storage,
       _secureStorage = secureStorage,
       _vaultEncryption = vaultEncryption,
       _sealLedgerRepository = sealLedgerRepository,
       _chainNotarizer = chainNotarizer,
       _nativeEnclave = nativeEnclave,
       _authRepository = authRepository;

  static const _vaultKeyName = 'snapseal:vault_key';

  final VaultDatabase _database;
  final LocalVaultStorage _storage;
  final FlutterSecureStorage _secureStorage;
  final VaultEncryptionHandler _vaultEncryption;
  final SealLedgerRepository _sealLedgerRepository;
  final ChainNotarizer _chainNotarizer;
  final NativeEnclaveChannel _nativeEnclave;
  final AuthRepository _authRepository;

  /// ProofLock pipeline: isolate hash → preflight RPC → TEE sign → simulated chain
  /// → AES-GCM local vault → `proof_ledger` → burn source.
  Future<SealCaptureResult> proofLockFile(File sourceFile, String userId) async {
    final path = sourceFile.path;
    final mimeType = _inferMimeType(path);

    final bundle = await _readFileAndSha256InIsolate(path);
    final fileHash = bundle.hash;
    final rawMediaBytes = bundle.bytes;

    var pendingRemoteSync =
        !_sealLedgerRepository.isConfigured || userId.trim().isEmpty;
    String? chainTxHash;

    if (!pendingRemoteSync) {
      try {
        final status = await _sealLedgerRepository.checkProofStatus(fileHash);
        if (status != 'new') {
          throw ProofLockConflictException(status);
        }
      } on ProofLockConflictException {
        rethrow;
      } catch (e) {
        if (_isRecoverableRemoteFailure(e)) {
          pendingRemoteSync = true;
        } else {
          rethrow;
        }
      }
    }

    final deviceSignature = await _nativeEnclave.signHash(fileHash);

    if (!pendingRemoteSync) {
      try {
        chainTxHash = await _chainNotarizer.notarizeFileHash(
          fileHash: fileHash,
          deviceSignature: deviceSignature,
        );
      } catch (e) {
        if (_isRecoverableRemoteFailure(e)) {
          pendingRemoteSync = true;
          chainTxHash = null;
        } else {
          rethrow;
        }
      }
    }

    await _persistSealedBytes(
      rawMediaBytes,
      mimeType: mimeType,
      assetFingerprint: fileHash,
    );

    var pendingSync = true;

    if (!pendingRemoteSync && chainTxHash != null) {
      try {
        await _sealLedgerRepository.insertProofLedgerRow(
          assetHash: fileHash,
          deviceSignature: deviceSignature,
          chainTxHash: chainTxHash,
        );
        pendingSync = false;
      } on PostgrestException catch (e) {
        if (e.code == '23505') {
          pendingSync = false;
        } else if (_isRecoverableRemoteFailure(e)) {
          pendingSync = true;
        } else {
          rethrow;
        }
      } catch (e) {
        if (_isRecoverableRemoteFailure(e)) {
          pendingSync = true;
        } else {
          rethrow;
        }
      }
    } else {
      pendingSync = pendingRemoteSync;
    }

    await _database.setPendingSync(
      assetFingerprint: fileHash,
      pendingSync: pendingSync,
    );

    await _deleteSourceAfterSeal(path);

    return SealCaptureResult(
      assetFingerprint: fileHash,
      pendingSync: pendingSync,
      chainTxHash: chainTxHash,
    );
  }

  Future<String> sealAndStore(
    Uint8List rawMediaBytes, {
    String? mimeType,
    required String userId,
  }) async {
    final tempDir = await Directory.systemTemp.createTemp('snapseal_seal_');
    final tempFile = File('${tempDir.path}/media.bin');
    try {
      await tempFile.writeAsBytes(rawMediaBytes, flush: true);
      final result = await proofLockFile(tempFile, userId);
      return result.assetFingerprint;
    } finally {
      await tempDir.delete(recursive: true);
    }
  }

  Future<SealCaptureResult> sealAndStoreCapture(
    XFile capturedFile, {
    required String userId,
  }) async {
    final path = capturedFile.path;
    try {
      return await proofLockFile(File(path), userId);
    } finally {
      await _deleteTemporaryCapture(path);
    }
  }

  Future<({String hash, Uint8List bytes})> _readFileAndSha256InIsolate(
    String path,
  ) {
    return Isolate.run(() {
      final bytes = File(path).readAsBytesSync();
      final hash = crypto.sha256.convert(bytes).toString();
      return (hash: hash, bytes: bytes);
    });
  }

  /// Persists encrypted media + SQLite row. Returns whether local row wants sync.
  Future<void> _persistSealedBytes(
    Uint8List rawMediaBytes, {
    required String? mimeType,
    required String assetFingerprint,
  }) async {
    final keyBytes = await _loadOrCreateKeyBytes();
    final encryptedBytes = await _vaultEncryption.encrypt(
      bytes: rawMediaBytes,
      keyBytes: keyBytes,
    );
    final thumbnailBytes =
        await _vaultEncryption.generateThumbnail(rawMediaBytes);

    final encryptedPath = await _storage.writeEncryptedOriginal(
      assetFingerprint: assetFingerprint,
      bytes: encryptedBytes,
    );
    final thumbnailPath = await _storage.writeThumbnail(
      assetFingerprint: assetFingerprint,
      bytes: thumbnailBytes,
    );

    try {
      await _database.upsertArchiveItem(
        ArchiveItem(
          assetFingerprint: assetFingerprint,
          encryptedPath: encryptedPath,
          thumbnailPath: thumbnailPath,
          byteLength: rawMediaBytes.length,
          mimeType: mimeType,
          createdAt: DateTime.now().toUtc(),
          pendingSync: true,
          title: null,
          description: null,
          syncAttemptCount: 0,
          lastSyncAttemptAt: null,
          nextRetryAt: null,
        ),
      );
    } catch (_) {
      // Compensating cleanup keeps local vault + SQLite metadata consistent.
      await _storage.deleteAssetFiles(
        encryptedPath: encryptedPath,
        thumbnailPath: thumbnailPath,
      );
      rethrow;
    }
  }

  /// If the thumbnail file is missing but the encrypted original exists, decrypt,
  /// verify the SHA-256 fingerprint, regenerate a JPEG thumbnail (image media), and
  /// write it under the vault. Returns [item] unchanged if the thumb exists,
  /// the original is missing, verification fails, or decode/thumbnail generation fails
  /// (e.g. non-image sealed payload).
  Future<ArchiveItem> regenerateMissingThumbnail(ArchiveItem item) async {
    if (_localFileExists(item.thumbnailPath)) {
      return item;
    }
    if (!_localFileExists(item.encryptedPath)) {
      return item;
    }

    try {
      final keyBytes = await _loadOrCreateKeyBytes();
      final encryptedBytes =
          await _storage.readEncryptedOriginal(item.encryptedPath);
      final clearBytes = await _vaultEncryption.decrypt(
        encryptedPayload: encryptedBytes,
        keyBytes: keyBytes,
      );
      final verifiedFingerprint =
          await _vaultEncryption.generateHash(clearBytes);
      if (verifiedFingerprint != item.assetFingerprint) {
        return item;
      }

      final thumbnailBytes =
          await _vaultEncryption.generateThumbnail(clearBytes);
      if (thumbnailBytes.isEmpty) {
        return item;
      }

      final thumbnailPath = await _storage.writeThumbnail(
        assetFingerprint: item.assetFingerprint,
        bytes: thumbnailBytes,
      );

      return ArchiveItem(
        assetFingerprint: item.assetFingerprint,
        encryptedPath: item.encryptedPath,
        thumbnailPath: thumbnailPath,
        byteLength: item.byteLength,
        createdAt: item.createdAt,
        pendingSync: item.pendingSync,
        mimeType: item.mimeType,
        title: item.title,
        description: item.description,
        syncAttemptCount: item.syncAttemptCount,
        lastSyncAttemptAt: item.lastSyncAttemptAt,
        nextRetryAt: item.nextRetryAt,
      );
    } catch (_) {
      return item;
    }
  }

  bool _localFileExists(String path) {
    try {
      return File(path).existsSync();
    } on FileSystemException {
      return false;
    }
  }

  Future<SealedAsset> extractForCourier(String assetFingerprint) async {
    final item = await _database.findArchiveItem(assetFingerprint);
    if (item == null) {
      throw StateError('No sealed asset exists for $assetFingerprint.');
    }

    final resolved = await _storage.resolveArchivePaths(item);
    if (resolved.thumbnailPath != item.thumbnailPath ||
        resolved.encryptedPath != item.encryptedPath) {
      await _database.upsertArchiveItem(resolved);
    }

    final keyBytes = await _loadOrCreateKeyBytes();
    final encryptedBytes = await _storage.readEncryptedOriginal(
      resolved.encryptedPath,
    );
    final clearBytes = await CourierCrypto.decryptAndVerifyFingerprint(
      vault: _vaultEncryption,
      encryptedPayload: encryptedBytes,
      keyBytes: keyBytes,
      expectedFingerprint: assetFingerprint,
    );

    return SealedAsset(assetFingerprint: assetFingerprint, bytes: clearBytes);
  }

  Future<void> burnLocalWallet() async {
    await _database.deleteAll();
    await _storage.deleteAll();
    await _secureStorage.delete(key: _vaultKeyName);
  }

  /// Background-friendly: `seal_ledger` active-wallet row + proof ledger completion.
  /// Returns `true` if [pending_sync] was cleared for this asset.
  Future<bool> retryPendingRemoteSync(String assetFingerprint) async {
    final item = await _database.findArchiveItem(assetFingerprint);
    if (item == null || !item.pendingSync) {
      return false;
    }
    if (!_sealLedgerRepository.isConfigured) {
      return false;
    }
    final userId = _authRepository.currentUserId;
    if (userId == null || userId.isEmpty) {
      return false;
    }

    try {
      await _sealLedgerRepository.syncAssetFingerprint(assetFingerprint);
    } catch (_) {
      // Best-effort: `seal_ledger` replica; proof path below is authoritative.
    }

    var pendingRemote = false;
    try {
      final status = await _sealLedgerRepository.checkProofStatus(assetFingerprint);
      if (status == 'owned_by_other') {
        return false;
      }
      if (status == 'owned_by_me') {
        await _database.markSyncSucceeded(assetFingerprint: assetFingerprint);
        return true;
      }
    } catch (e) {
      if (_isRecoverableRemoteFailure(e)) {
        pendingRemote = true;
      } else {
        return false;
      }
    }

    final deviceSignature = await _nativeEnclave.signHash(assetFingerprint);

    String? chainTxHash;
    if (!pendingRemote) {
      try {
        chainTxHash = await _chainNotarizer.notarizeFileHash(
          fileHash: assetFingerprint,
          deviceSignature: deviceSignature,
        );
      } catch (e) {
        if (_isRecoverableRemoteFailure(e)) {
          pendingRemote = true;
        } else {
          return false;
        }
      }
    }

    if (pendingRemote || chainTxHash == null) {
      await _database.markSyncDeferred(
        assetFingerprint: assetFingerprint,
        nextRetryAt: _nextRetryAt(item.syncAttemptCount + 1),
      );
      return false;
    }

    try {
      await _sealLedgerRepository.insertProofLedgerRow(
        assetHash: assetFingerprint,
        deviceSignature: deviceSignature,
        chainTxHash: chainTxHash,
      );
      await _database.markSyncSucceeded(assetFingerprint: assetFingerprint);
      return true;
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        await _database.markSyncSucceeded(assetFingerprint: assetFingerprint);
        return true;
      }
      if (_isRecoverableRemoteFailure(e)) {
        await _database.markSyncDeferred(
          assetFingerprint: assetFingerprint,
          nextRetryAt: _nextRetryAt(item.syncAttemptCount + 1),
        );
        return false;
      }
      rethrow;
    } catch (e) {
      if (_isRecoverableRemoteFailure(e)) {
        await _database.markSyncDeferred(
          assetFingerprint: assetFingerprint,
          nextRetryAt: _nextRetryAt(item.syncAttemptCount + 1),
        );
        return false;
      }
      return false;
    }
  }

  /// Backoff from [syncAttemptCountAfterThisFailure] (matches `sync_attempt_count`
  /// written by [VaultDatabase.markSyncDeferred], i.e. after incrementing for this deferral).
  DateTime _nextRetryAt(int syncAttemptCountAfterThisFailure) {
    const maxBackoffMinutes = 60;
    final exp = syncAttemptCountAfterThisFailure.clamp(0, 10);
    final minutes = (1 << exp).clamp(1, maxBackoffMinutes);
    return DateTime.now().toUtc().add(Duration(minutes: minutes));
  }

  Future<Uint8List> _loadOrCreateKeyBytes() async {
    final existing = await _secureStorage.read(key: _vaultKeyName);
    if (existing != null) {
      return _vaultEncryption.decodeKey(existing);
    }

    final keyBytes = _vaultEncryption.generateKeyBytes();
    await _secureStorage.write(
      key: _vaultKeyName,
      value: _vaultEncryption.encodeKey(keyBytes),
    );
    return keyBytes;
  }

  String _inferMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) {
      return 'image/heic';
    }
    return 'image/jpeg';
  }

  Future<void> _deleteTemporaryCapture(String path) async {
    try {
      await Isolate.run(() {
        final file = File(path);
        if (file.existsSync()) {
          file.deleteSync();
        }
      });
    } catch (_) {
      // Best-effort privacy cleanup; do not mask the sealing outcome.
    }
  }

  Future<void> _deleteSourceAfterSeal(String path) async {
    await _deleteTemporaryCapture(path);
  }

  bool _isRecoverableRemoteFailure(Object error) {
    if (error is SocketException) return true;
    if (error is HandshakeException) return true;
    if (error is TimeoutException) return true;
    final message = error.toString().toLowerCase();
    return message.contains('socket') ||
        message.contains('connection refused') ||
        message.contains('network is unreachable') ||
        message.contains('failed host lookup') ||
        message.contains('timed out') ||
        message.contains('connection reset') ||
        message.contains('connection closed');
  }
}
