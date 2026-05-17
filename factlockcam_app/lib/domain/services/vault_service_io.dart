import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:postgrest/postgrest.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as video_thumbnail;

import '../../core/config/app_config.dart';
import '../../core/crypto/courier_crypto.dart';
import '../../core/crypto/vault_encryption_handler.dart';
import '../../core/di/locator.dart';
import '../../core/ghost_key/native_enclave_channel.dart';
import '../../data/local/vault_database.dart';
import '../../data/models/archive_item.dart';
import '../../data/models/sealed_asset.dart';
import '../../data/services/local_vault_storage.dart';
import '../../data/services/vault_path_resolver.dart';
import '../../data/supabase/auth_repository.dart';
import '../../data/supabase/seal_ledger_repository.dart';
import '../blockchain/chain_notarizer.dart';

final vaultServiceProvider = Provider<VaultService>(
  (ref) => getIt<VaultService>(),
);

String videoThumbnailTempExtensionForMime(String? mimeType) {
  final normalized = mimeType?.trim().toLowerCase();
  switch (normalized) {
    case 'video/quicktime':
      return '.mov';
    case 'video/webm':
      return '.webm';
    case 'video/3gpp':
      return '.3gp';
    case 'video/x-msvideo':
      return '.avi';
    case 'video/mpeg':
      return '.mpeg';
    case 'video/mp4':
    case 'video/x-m4v':
    case null:
    case '':
      return '.mp4';
    default:
      return '.mp4';
  }
}

/// Strips leading slashes so Storage RLS `split_part(..., '/', 1)` matches [auth.uid()].
String _normalizedCourierBlobPath(String raw) {
  var path = raw.trim();
  while (path.startsWith('/')) {
    path = path.substring(1);
  }
  return path;
}

bool _courierWebVaultHostLooksMachineLocal(Uri uri) {
  if (!uri.hasAuthority) return false;
  final h = uri.host.toLowerCase();
  return h == 'localhost' || h == '127.0.0.1' || h == '::1';
}

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
    VaultPathResolver? pathResolver,
  }) : _database = database,
       _storage = storage,
       _secureStorage = secureStorage,
       _vaultEncryption = vaultEncryption,
       _sealLedgerRepository = sealLedgerRepository,
       _chainNotarizer = chainNotarizer,
       _nativeEnclave = nativeEnclave,
       _authRepository = authRepository,
       _pathResolver = pathResolver ?? VaultPathResolver(storage);

  static const _vaultKeyName = 'factlockcam:vault_key';
  static const _legacyVaultKeyName = 'snapseal:vault_key';

  /// Compile-time **only**. Has no Dart default — empty means "not passed"; see [_effectiveCourierWebVaultBase].
  static const String _webVaultCompilerDefine = String.fromEnvironment(
    'WEB_VAULT_BASE_URL',
  );

  final VaultDatabase _database;
  final LocalVaultStorage _storage;
  final FlutterSecureStorage _secureStorage;
  final VaultEncryptionHandler _vaultEncryption;
  final SealLedgerRepository _sealLedgerRepository;
  final ChainNotarizer _chainNotarizer;
  final NativeEnclaveChannel _nativeEnclave;
  final AuthRepository _authRepository;
  final VaultPathResolver _pathResolver;

  /// Courier vault origin embedded in shared links.
  ///
  /// **Precedence**: any non-empty `String.fromEnvironment('WEB_VAULT_BASE_URL')`
  /// wins (tunnel, staging, prod). Fallback to `http://localhost:3000` exists **only**
  /// in debug when the define was not passed — it never replaces an explicit dart-define.
  String _effectiveCourierWebVaultBase() {
    final trimmed = _webVaultCompilerDefine.trim();
    if (trimmed.isNotEmpty) {
      return AppConfig.normalizeSupabaseProjectUrl(trimmed);
    }
    if (kDebugMode) return 'http://localhost:3000';
    throw StateError(
      'WEB_VAULT_BASE_URL is unset. For profile/release QA, pass '
      '`--dart-define=WEB_VAULT_BASE_URL=https://YOUR-NGROK-SUBDOMAIN.ngrok-free.app` '
      '(or tunnel equivalent) built from dart_defines / launch tooling.',
    );
  }

  /// ProofLock pipeline: isolate hash → preflight RPC → TEE sign → simulated chain
  /// → AES-GCM local vault → `proof_ledger` → burn source.
  ///
  /// **Ordering:** Ledger preflight, device signing, and chain notarization run
  /// before [`_persistSealedBytes`]. A thrown [`ProofLockConflictException`] therefore
  /// exits before any encrypted vault files or SQLite archive rows are written, so no
  /// orphan assets are created by that conflict path alone.
  Future<SealCaptureResult> proofLockFile(
    File sourceFile,
    String userId,
  ) async {
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

    String? deviceSignature;
    if (!pendingRemoteSync) {
      try {
        deviceSignature = await _nativeEnclave.signHash(fileHash);
      } catch (e) {
        if (_isRecoverableRemoteFailure(e)) {
          pendingRemoteSync = true;
        } else {
          rethrow;
        }
      }
    }

    if (!pendingRemoteSync && deviceSignature != null) {
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
      sourcePath: path,
    );

    var pendingSync = true;

    if (!pendingRemoteSync && deviceSignature != null && chainTxHash != null) {
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
    final tempDir = await Directory.systemTemp.createTemp('factlockcam_seal_');
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

  Future<String> createCourierPackage({
    required String assetHash,
    required String verifierPassword,
  }) async {
    final userId = _authRepository.currentUserId;
    if (userId == null || userId.isEmpty) {
      throw StateError('No authenticated user for courier package creation.');
    }
    if (!_sealLedgerRepository.isConfigured) {
      throw StateError(
        'Supabase is not configured. Run with --dart-define SUPABASE_URL=... '
        'and --dart-define SUPABASE_ANON_KEY=...',
      );
    }

    final courierVaultBase = _effectiveCourierWebVaultBase();
    final vaultBaseParsed = Uri.tryParse(courierVaultBase);
    if (!kDebugMode &&
        vaultBaseParsed != null &&
        _courierWebVaultHostLooksMachineLocal(vaultBaseParsed)) {
      throw StateError(
        'WEB_VAULT_BASE_URL points at localhost ($courierVaultBase). Recipients '
        'on another device cannot reach it — use an HTTPS tunnel (Ngrok, etc.), '
        'pass that origin via dart-define, rebuild the iOS app, then regenerate the link.',
      );
    }

    final item = await _database.findArchiveItem(assetHash);
    if (item == null) {
      throw StateError('No sealed asset exists for $assetHash.');
    }

    final resolved = await _pathResolver.resolve(item);
    if (resolved.thumbnailPath != item.thumbnailPath ||
        resolved.encryptedPath != item.encryptedPath) {
      await _database.upsertArchiveItem(resolved);
    }

    final encryptedBytes = await _storage.readEncryptedOriginal(
      resolved.encryptedPath,
    );
    final keyBytes = await _loadOrCreateKeyBytes();
    final encodedVaultKey = _vaultEncryption.encodeKey(keyBytes);
    final fileExtension = _fileExtensionForMimeType(resolved.mimeType);
    final storagePath = _normalizedCourierBlobPath(
      '$userId/$assetHash$fileExtension.seal',
    );

    await _sealLedgerRepository.uploadCourierEncryptedBlob(
      storagePath: storagePath,
      encryptedBytes: encryptedBytes,
    );

    final packageId = await _sealLedgerRepository.getOrCreateCourierPackage(
      assetHash: assetHash,
      verifierPassword: verifierPassword,
      encodedVaultKey: encodedVaultKey,
      fileExtension: fileExtension,
      storagePath: storagePath,
    );

    final base = courierVaultBase.endsWith('/')
        ? courierVaultBase.substring(0, courierVaultBase.length - 1)
        : courierVaultBase;
    return '$base/courier?pkg=${Uri.encodeQueryComponent(packageId)}';
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
    String? sourcePath,
  }) async {
    final keyBytes = await _loadOrCreateKeyBytes();
    final encryptedBytes = await _vaultEncryption.encrypt(
      bytes: rawMediaBytes,
      keyBytes: keyBytes,
    );
    final thumbnailBytes = await _generateThumbnailBytes(
      rawMediaBytes,
      mimeType: mimeType,
      sourcePath: sourcePath,
    );

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
  /// verify the SHA-256 fingerprint, regenerate a JPEG thumbnail, and
  /// write it under the vault. Returns [item] unchanged if the thumb exists,
  /// the original is missing, verification fails, or decode/thumbnail generation fails
  /// (e.g. unsupported media payload).
  Future<ArchiveItem> regenerateMissingThumbnail(ArchiveItem item) async {
    if (_thumbnailFileExists(item.thumbnailPath)) {
      return item;
    }
    if (!_localFileExists(item.encryptedPath)) {
      return item;
    }

    try {
      final keyBytes = await _loadOrCreateKeyBytes();
      final encryptedBytes = await _storage.readEncryptedOriginal(
        item.encryptedPath,
      );
      final clearBytes = await _vaultEncryption.decrypt(
        encryptedPayload: encryptedBytes,
        keyBytes: keyBytes,
      );
      final verifiedFingerprint = await _vaultEncryption.generateHash(
        clearBytes,
      );
      if (verifiedFingerprint != item.assetFingerprint) {
        return item;
      }

      final thumbnailBytes = await _generateThumbnailBytes(
        clearBytes,
        mimeType: item.mimeType,
      );
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

  /// DB rows plus path resolution and missing-thumbnail regeneration (same path as dashboard load).
  Future<List<ArchiveItem>> listArchiveItems() async {
    final raw = await _database.listArchiveItems();
    final out = <ArchiveItem>[];
    for (final item in raw) {
      var next = await _pathResolver.resolve(item);
      next = await regenerateMissingThumbnail(next);
      out.add(next);
      if (next.thumbnailPath != item.thumbnailPath ||
          next.encryptedPath != item.encryptedPath) {
        await _database.upsertArchiveItem(next);
      }
    }
    return out;
  }

  Future<void> updateArchiveMetadata({
    required String assetFingerprint,
    required String? title,
    required String? description,
  }) async {
    final existing = await _database.findArchiveItem(assetFingerprint);
    if (existing == null) {
      return;
    }

    final normalizedTitle = _normalizeMetadataField(title);
    final normalizedDescription = _normalizeMetadataField(description);
    if (normalizedTitle == existing.title &&
        normalizedDescription == existing.description) {
      return;
    }

    await _database.updateArchiveMetadata(
      assetFingerprint: assetFingerprint,
      title: normalizedTitle,
      description: normalizedDescription,
    );
  }

  String? _normalizeMetadataField(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  bool _localFileExists(String path) {
    try {
      return File(path).existsSync();
    } on FileSystemException {
      return false;
    }
  }

  bool _thumbnailFileExists(String path) {
    try {
      final file = File(path);
      return file.existsSync() && file.lengthSync() > 0;
    } on FileSystemException {
      return false;
    }
  }

  Future<Uint8List> _generateThumbnailBytes(
    Uint8List rawMediaBytes, {
    required String? mimeType,
    String? sourcePath,
  }) async {
    if (mimeType?.startsWith('video/') ?? false) {
      return _generateVideoThumbnailBytes(
        rawMediaBytes,
        mimeType: mimeType,
        sourcePath: sourcePath,
      );
    }
    return _vaultEncryption.generateThumbnail(rawMediaBytes);
  }

  Future<Uint8List> _generateVideoThumbnailBytes(
    Uint8List rawMediaBytes, {
    required String? mimeType,
    String? sourcePath,
  }) async {
    final existingPath = sourcePath;
    if (existingPath != null && _localFileExists(existingPath)) {
      final bytes = await video_thumbnail.VideoThumbnail.thumbnailData(
        video: existingPath,
        imageFormat: video_thumbnail.ImageFormat.JPEG,
        maxWidth: 320,
        quality: 72,
      );
      return bytes ?? Uint8List(0);
    }

    final tempDir = await Directory.systemTemp.createTemp(
      'factlockcam_video_thumb_',
    );
    final extension = videoThumbnailTempExtensionForMime(mimeType);
    final tempFile = File('${tempDir.path}/source$extension');
    try {
      await tempFile.writeAsBytes(rawMediaBytes, flush: true);
      final bytes = await video_thumbnail.VideoThumbnail.thumbnailData(
        video: tempFile.path,
        imageFormat: video_thumbnail.ImageFormat.JPEG,
        maxWidth: 320,
        quality: 72,
      );
      return bytes ?? Uint8List(0);
    } finally {
      await tempDir.delete(recursive: true);
    }
  }

  Future<SealedAsset> extractForCourier(String assetFingerprint) async {
    final item = await _database.findArchiveItem(assetFingerprint);
    if (item == null) {
      throw StateError('No sealed asset exists for $assetFingerprint.');
    }

    final resolved = await _pathResolver.resolve(item);
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
    await _secureStorage.delete(key: _legacyVaultKeyName);
  }

  /// Removes the local SQLite row and encrypted + thumbnail files for one asset.
  ///
  /// Does **not** delete remote `proof_ledger` / chain artifacts; those may
  /// remain as historical records on Supabase.
  Future<void> deleteArchiveItem(String assetFingerprint) async {
    final item = await _database.findArchiveItem(assetFingerprint);
    if (item == null) {
      return;
    }
    final resolved = await _pathResolver.resolve(item);
    await _storage.deleteAssetFiles(
      encryptedPath: resolved.encryptedPath,
      thumbnailPath: resolved.thumbnailPath,
    );
    await _database.deleteArchiveItem(assetFingerprint);
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
      final status = await _sealLedgerRepository.checkProofStatus(
        assetFingerprint,
      );
      // `anonymous`: ledger row exists but no profile claims its wallet — signing
      // and notarization retries cannot fix that; stop looping like `owned_by_me`.
      if (status == 'anonymous' || status == 'owned_by_me') {
        await _database.markSyncSucceeded(assetFingerprint: assetFingerprint);
        return true;
      }
      if (status == 'owned_by_other') {
        return false;
      }
    } catch (e) {
      if (_isRecoverableRemoteFailure(e)) {
        pendingRemote = true;
      } else {
        return false;
      }
    }

    String? deviceSignature;
    try {
      deviceSignature = await _nativeEnclave.signHash(assetFingerprint);
    } catch (e) {
      if (_isRecoverableRemoteFailure(e)) {
        pendingRemote = true;
      } else {
        return false;
      }
    }

    String? chainTxHash;
    final signature = deviceSignature;
    if (!pendingRemote && signature != null) {
      try {
        chainTxHash = await _chainNotarizer.notarizeFileHash(
          fileHash: assetFingerprint,
          deviceSignature: signature,
        );
      } catch (e) {
        if (_isRecoverableRemoteFailure(e)) {
          pendingRemote = true;
        } else {
          return false;
        }
      }
    }

    if (pendingRemote || chainTxHash == null || signature == null) {
      await _database.markSyncDeferred(
        assetFingerprint: assetFingerprint,
        nextRetryAt: _nextRetryAt(item.syncAttemptCount + 1),
      );
      return false;
    }

    try {
      await _sealLedgerRepository.insertProofLedgerRow(
        assetHash: assetFingerprint,
        deviceSignature: signature,
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
    var existing = await _secureStorage.read(key: _vaultKeyName);
    if (existing != null) {
      return _vaultEncryption.decodeKey(existing);
    }
    existing = await _secureStorage.read(key: _legacyVaultKeyName);
    if (existing != null) {
      final keyBytes = _vaultEncryption.decodeKey(existing);
      await _secureStorage.write(key: _vaultKeyName, value: existing);
      await _secureStorage.delete(key: _legacyVaultKeyName);
      return keyBytes;
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
    if (lower.endsWith('.mov')) {
      return 'video/quicktime';
    }
    if (lower.endsWith('.mp4') || lower.endsWith('.m4v')) {
      return 'video/mp4';
    }
    if (lower.endsWith('.webm')) {
      return 'video/webm';
    }
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    return 'application/octet-stream';
  }

  String _fileExtensionForMimeType(String? mimeType) {
    return switch (mimeType?.trim().toLowerCase()) {
      'image/png' => '.png',
      'image/heic' || 'image/heif' => '.heic',
      'video/quicktime' => '.mov',
      'video/webm' => '.webm',
      'video/mp4' || 'video/x-m4v' => '.mp4',
      _ => '.jpg',
    };
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
