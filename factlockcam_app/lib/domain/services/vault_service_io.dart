import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image/image.dart' as img;
import 'package:postgrest/postgrest.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as video_thumbnail;

import '../../application/vault/vault_sync_coordinator.dart';
import '../../core/config/app_config.dart';
import '../../core/crypto/courier_crypto.dart';
import '../../core/crypto/vault_encryption_handler.dart';
import '../../core/di/locator.dart';
import '../../core/journal/journal_repository.dart';
import '../../core/journal/transactional_archive_persister.dart';
import '../../core/lock/isolate_lock_coordinator.dart';
import '../../core/ghost_key/key_custody_service.dart';
import '../../core/ghost_key/key_storage_keys.dart';
import '../../core/ghost_key/native_enclave_channel.dart';
import '../../data/local/vault_database.dart';
import '../../data/models/archive_item.dart';
import '../../data/models/sealed_asset.dart';
import '../../data/services/local_vault_storage.dart';
import '../../data/services/vault_path_resolver.dart';
import '../../data/supabase/auth_repository.dart';
import '../../data/supabase/seal_ledger_repository.dart';
import '../blockchain/chain_notarizer.dart';
import '../blockchain/vault_blockchain_handler.dart';
import '../blockchain/wallet_service.dart';
import '../../features/archive/application/proof_courier_service.dart';
import 'proof_sync_notifier.dart';

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

bool _courierWebArchiveHostLooksMachineLocal(Uri uri) {
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
    required WalletService walletService,
    required VaultBlockchainHandler blockchainHandler,
    required ProofSyncNotifier proofSyncNotifier,
    required NativeEnclaveChannel nativeEnclave,
    required AuthRepository authRepository,
    ProofCourierService? proofCourierService,
    TransactionalArchivePersister? transactionalPersister,
    VaultPathResolver? pathResolver,
    VaultSyncCoordinator? vaultSyncCoordinator,
  }) : _database = database,
       _storage = storage,
       _secureStorage = secureStorage,
       _vaultEncryption = vaultEncryption,
       _sealLedgerRepository = sealLedgerRepository,
       _chainNotarizer = chainNotarizer,
       _walletService = walletService,
       _blockchainHandler = blockchainHandler,
       _proofSyncNotifier = proofSyncNotifier,
       _nativeEnclave = nativeEnclave,
       _authRepository = authRepository,
       _proofCourierService = proofCourierService,
       _transactionalPersister = transactionalPersister,
       _pathResolver = pathResolver ?? VaultPathResolver(storage),
       _vaultSyncCoordinator = vaultSyncCoordinator;

  static const _vaultKeyName = KeyStorageKeys.vaultAesKey;
  static const _legacyVaultKeyName = KeyStorageKeys.legacyVaultAesKey;

  /// Compile-time **only**. Has no Dart default — empty means "not passed"; see [_effectiveCourierWebArchiveBase].
  static const String _webArchiveCompilerDefine = String.fromEnvironment(
    'WEB_ARCHIVE_BASE_URL',
  );

  final VaultDatabase _database;
  final LocalVaultStorage _storage;
  final FlutterSecureStorage _secureStorage;
  final VaultEncryptionHandler _vaultEncryption;
  final SealLedgerRepository _sealLedgerRepository;
  final ChainNotarizer _chainNotarizer;
  final WalletService _walletService;
  final VaultBlockchainHandler _blockchainHandler;
  final ProofSyncNotifier _proofSyncNotifier;
  final NativeEnclaveChannel _nativeEnclave;
  final AuthRepository _authRepository;
  final ProofCourierService? _proofCourierService;
  final TransactionalArchivePersister? _transactionalPersister;
  final VaultPathResolver _pathResolver;
  final VaultSyncCoordinator? _vaultSyncCoordinator;
  Future<void>? _captureSealChain;

  Future<T> _enqueueCaptureSeal<T>(Future<T> Function() action) async {
    final previous = _captureSealChain;
    final gate = Completer<void>();
    _captureSealChain = gate.future;
    try {
      if (previous != null) {
        await previous;
      }
      return await action();
    } finally {
      if (!gate.isCompleted) {
        gate.complete();
      }
      if (identical(_captureSealChain, gate.future)) {
        _captureSealChain = null;
      }
    }
  }

  /// Courier archive origin embedded in shared links.
  ///
  /// **Precedence**: any non-empty `String.fromEnvironment('WEB_ARCHIVE_BASE_URL')`
  /// wins (tunnel, staging, prod). Fallback to `http://localhost:3000` exists **only**
  /// in debug when the define was not passed — it never replaces an explicit dart-define.
  String _effectiveCourierWebArchiveBase() {
    final trimmed = _webArchiveCompilerDefine.trim();
    if (trimmed.isNotEmpty) {
      return AppConfig.normalizeSupabaseProjectUrl(trimmed);
    }
    if (kDebugMode) return 'http://localhost:3000';
    throw StateError(
      'WEB_ARCHIVE_BASE_URL is unset. Release/profile builds must pass '
      '`--dart-define=WEB_ARCHIVE_BASE_URL=https://archive.factlockcam.com` '
      'via dart_defines.json or launch tooling.',
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
    if (AppConfig.usePolygonNotarizer) {
      return _proofLockFilePolygonSaga(sourceFile, userId);
    }
    return _proofLockFileSimulated(sourceFile, userId);
  }

  /// Simulated chain: synchronous notarization before local persist (legacy path).
  Future<SealCaptureResult> _proofLockFileSimulated(
    File sourceFile,
    String userId,
  ) async {
    final path = sourceFile.path;
    final mimeType = _inferMimeType(path);
    final bundle = await _readFileAndSha256InIsolate(path);
    try {
      return await _proofLockBytesSimulated(
        bundle,
        userId,
        mimeType: mimeType,
        sourcePath: path,
      );
    } finally {
      await _deleteSourceAfterSeal(path);
    }
  }

  Future<SealCaptureResult> _proofLockBytesSimulated(
    ({String hash, Uint8List bytes}) bundle,
    String userId, {
    required String mimeType,
    String? sourcePath,
  }) async {
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
      sourcePath: sourcePath,
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
    if (!pendingSync && chainTxHash != null) {
      await _database.markSyncSucceeded(
        assetFingerprint: fileHash,
        chainTxHash: chainTxHash,
      );
    }

    await _attemptCloudVaultSync(
      sourcePath: sourcePath,
      fileHash: fileHash,
      mimeType: mimeType,
      userId: userId,
    );

    return SealCaptureResult(
      assetFingerprint: fileHash,
      pendingSync: pendingSync,
      chainTxHash: chainTxHash,
    );
  }

  /// Polygon saga: local persist + pending ledger row, then await relay.
  Future<SealCaptureResult> _proofLockFilePolygonSaga(
    File sourceFile,
    String userId,
  ) async {
    final path = sourceFile.path;
    final mimeType = _inferMimeType(path);
    final bundle = await _readFileAndSha256InIsolate(path);
    try {
      return await _proofLockBytesPolygonSaga(
        bundle,
        userId,
        mimeType: mimeType,
        sourcePath: path,
      );
    } finally {
      await _deleteSourceAfterSeal(path);
    }
  }

  Future<SealCaptureResult> _proofLockBytesPolygonSaga(
    ({String hash, Uint8List bytes}) bundle,
    String userId, {
    required String mimeType,
    String? sourcePath,
  }) async {
    final fileHash = bundle.hash;
    final rawMediaBytes = bundle.bytes;

    var pendingRemoteSync =
        !_sealLedgerRepository.isConfigured || userId.trim().isEmpty;

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
    String? ownerSignature;
    String? sealingWalletAddress;
    if (!pendingRemoteSync) {
      try {
        deviceSignature = await _nativeEnclave.signHash(fileHash);
        ownerSignature = await _walletService.signMessageHash(fileHash);
        sealingWalletAddress = await _walletService.ensureEvmAddress();
      } catch (e) {
        if (_isRecoverableRemoteFailure(e)) {
          pendingRemoteSync = true;
        } else {
          rethrow;
        }
      }
    }

    await _persistSealedBytes(
      rawMediaBytes,
      mimeType: mimeType,
      assetFingerprint: fileHash,
      sourcePath: sourcePath,
      walletAddress: sealingWalletAddress,
    );

    var pendingSync = true;
    String? chainTxHash;

    if (!pendingRemoteSync &&
        deviceSignature != null &&
        ownerSignature != null) {
      try {
        await _sealLedgerRepository.insertPendingProofLedgerRow(
          assetHash: fileHash,
          deviceSignature: deviceSignature,
        );
        chainTxHash = await _dispatchPolygonRelay(
          fileHash: fileHash,
          ownerSignature: ownerSignature,
          deviceSignature: deviceSignature,
        );
        pendingSync = chainTxHash == null;
      } on PostgrestException catch (e) {
        if (e.code == '23505') {
          chainTxHash = await _sealLedgerRepository.fetchProofChainTxHash(
            fileHash,
          );
          pendingSync = chainTxHash == null;
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
    if (chainTxHash != null) {
      await _database.markSyncSucceeded(
        assetFingerprint: fileHash,
        chainTxHash: chainTxHash,
      );
    }

    await _attemptCloudVaultSync(
      sourcePath: sourcePath,
      fileHash: fileHash,
      mimeType: mimeType,
      userId: userId,
    );

    return SealCaptureResult(
      assetFingerprint: fileHash,
      pendingSync: pendingSync,
      chainTxHash: chainTxHash,
    );
  }

  /// Returns the relay transaction hash when notarization completes.
  ///
  /// Relay failures propagate to callers so QA sees real configuration or
  /// broadcast errors instead of a silent pending-sync loop.
  Future<String?> _dispatchPolygonRelay({
    required String fileHash,
    required String ownerSignature,
    required String deviceSignature,
  }) async {
    final txHash = await _blockchainHandler.notarizeFileHash(
      fileHash: fileHash,
      ownerSignature: ownerSignature,
      deviceSignature: deviceSignature,
    );
    await _finalizeLocalPolygonSync(fileHash, chainTxHash: txHash);
    return txHash;
  }

  Future<void> _finalizeLocalPolygonSync(
    String assetFingerprint, {
    String? chainTxHash,
  }) async {
    final item = await _database.findArchiveItem(assetFingerprint);
    if (item == null) {
      return;
    }
    if (!item.pendingSync && item.chainTxHash != null) {
      return;
    }
    await _database.markSyncSucceeded(
      assetFingerprint: assetFingerprint,
      chainTxHash: chainTxHash,
    );
    _proofSyncNotifier.notifyAssetSynced(assetFingerprint);
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
    required Uint8List bufferedBytes,
  }) {
    final mimeType = _resolveCaptureMimeType(capturedFile.path, bufferedBytes);
    return _enqueueCaptureSeal(() async {
      final path = capturedFile.path;
      try {
        final bundle = await _hashBytesInIsolate(bufferedBytes);
        if (AppConfig.usePolygonNotarizer) {
          return _proofLockBytesPolygonSaga(
            bundle,
            userId,
            mimeType: mimeType,
            sourcePath: path,
          );
        }
        return _proofLockBytesSimulated(
          bundle,
          userId,
          mimeType: mimeType,
          sourcePath: path,
        );
      } finally {
        await _deleteTemporaryCapture(path);
      }
    });
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

    final courierArchiveBase = _effectiveCourierWebArchiveBase();
    final archiveBaseParsed = Uri.tryParse(courierArchiveBase);
    if (!kDebugMode &&
        archiveBaseParsed != null &&
        _courierWebArchiveHostLooksMachineLocal(archiveBaseParsed)) {
      throw StateError(
        'WEB_ARCHIVE_BASE_URL points at localhost ($courierArchiveBase). Recipients '
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
      assetFingerprint: assetHash,
    );
    final keyBytes = await _loadOrCreateKeyBytes();
    final encodedVaultKey = _vaultEncryption.encodeKey(keyBytes);
    final fileExtension = _fileExtensionForMimeType(resolved.mimeType);
    final storagePath = _normalizedCourierBlobPath(
      '$userId/$assetHash$fileExtension.seal',
    );

    await (_proofCourierService?.uploadEncryptedCourierBlob(
          storagePath: storagePath,
          encryptedBytes: encryptedBytes,
        ) ??
        _sealLedgerRepository.uploadCourierEncryptedBlob(
          storagePath: storagePath,
          encryptedBytes: encryptedBytes,
        ));

    final packageId = await _sealLedgerRepository.getOrCreateCourierPackage(
      assetHash: assetHash,
      verifierPassword: verifierPassword,
      encodedVaultKey: encodedVaultKey,
      fileExtension: fileExtension,
      storagePath: storagePath,
    );

    final base = courierArchiveBase.endsWith('/')
        ? courierArchiveBase.substring(0, courierArchiveBase.length - 1)
        : courierArchiveBase;
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

  Future<({String hash, Uint8List bytes})> _hashBytesInIsolate(
    Uint8List bytes,
  ) {
    return Isolate.run(() {
      final hash = crypto.sha256.convert(bytes).toString();
      return (hash: hash, bytes: bytes);
    });
  }

  String _resolveCaptureMimeType(String capturePath, Uint8List bytes) {
    final fromBytes = _inferMimeTypeFromBytes(bytes);
    if (fromBytes != 'application/octet-stream') {
      return fromBytes;
    }
    return _inferMimeType(capturePath);
  }

  String _inferMimeTypeFromBytes(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 12 &&
        bytes[4] == 0x66 &&
        bytes[5] == 0x74 &&
        bytes[6] == 0x79 &&
        bytes[7] == 0x70) {
      final brand = String.fromCharCodes(bytes.sublist(8, 12));
      if (brand.startsWith('heic') ||
          brand.startsWith('heix') ||
          brand.startsWith('mif1')) {
        return 'image/heic';
      }
      if (brand.startsWith('qt  ') || brand.startsWith('moov')) {
        return 'video/quicktime';
      }
      if (brand.startsWith('isom') || brand.startsWith('mp41')) {
        return 'video/mp4';
      }
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    return 'application/octet-stream';
  }

  /// Persists encrypted media + SQLite row inside a journal-backed transaction.
  Future<void> _persistSealedBytes(
    Uint8List rawMediaBytes, {
    required String? mimeType,
    required String assetFingerprint,
    String? sourcePath,
    String? walletAddress,
  }) async {
    final keyBytes = await _loadOrCreateKeyBytes();
    final thumbnailBytes = await _generateThumbnailBytes(
      rawMediaBytes,
      mimeType: mimeType,
      sourcePath: sourcePath,
    );
    if (!(mimeType?.startsWith('video/') ?? false) && thumbnailBytes.isEmpty) {
      throw StateError(
        'Thumbnail generation failed for captured media ($mimeType).',
      );
    }

    final encryptedBytes = await _vaultEncryption.encrypt(
      bytes: rawMediaBytes,
      keyBytes: keyBytes,
    );

    final persister = _transactionalPersister;
    if (persister == null) {
      throw StateError(
        'TransactionalArchivePersister is required for archive persistence.',
      );
    }

    await persister.persistSealedAsset(
      assetFingerprint: assetFingerprint,
      encryptedBytes: encryptedBytes,
      thumbnailBytes: thumbnailBytes,
      rawByteLength: rawMediaBytes.length,
      mimeType: mimeType,
      pendingSync: true,
      walletAddress: walletAddress,
    );

    await _verifyPersistedSealedAsset(
      assetFingerprint: assetFingerprint,
      keyBytes: keyBytes,
      expectedEncryptedLength: encryptedBytes.length,
    );
  }

  Future<void> _verifyPersistedSealedAsset({
    required String assetFingerprint,
    required Uint8List keyBytes,
    required int expectedEncryptedLength,
  }) async {
    final paths = await _storage.resolveTransactionalPaths(assetFingerprint);
    final encryptedPath = paths.encryptedFinalPath;
    final onDiskLength = await File(encryptedPath).length();
    if (onDiskLength != expectedEncryptedLength) {
      throw StateError(
        'Persist verification failed: encrypted payload length mismatch '
        'for $assetFingerprint (expected $expectedEncryptedLength, '
        'on disk $onDiskLength).',
      );
    }

    final encryptedBytes = await _storage.readEncryptedOriginal(
      encryptedPath,
      assetFingerprint: assetFingerprint,
    );

    await CourierCrypto.decryptAndVerifyFingerprint(
      vault: _vaultEncryption,
      encryptedPayload: encryptedBytes,
      keyBytes: keyBytes,
      expectedFingerprint: assetFingerprint,
    );
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
        assetFingerprint: item.assetFingerprint,
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

  /// DB rows plus path resolution. Thumbnail repair runs after return so the
  /// hub/archive shell is not blocked decrypting every `.seal` on cold start.
  Future<List<ArchiveItem>> listArchiveItems() async {
    final raw = await _database.listArchiveItems();
    final out = <ArchiveItem>[];
    for (final item in raw) {
      out.add(await _pathResolver.resolve(item));
    }
    unawaited(_repairMissingThumbnailsInBackground(out));
    return out;
  }

  Future<void> _repairMissingThumbnailsInBackground(
    List<ArchiveItem> items,
  ) async {
    for (final item in items) {
      try {
        final repaired = await regenerateMissingThumbnail(item);
        if (repaired.thumbnailPath != item.thumbnailPath ||
            repaired.encryptedPath != item.encryptedPath) {
          await _database.upsertArchiveItem(repaired);
        }
      } catch (_) {
        // Best-effort repair; dashboard refresh picks up successful writes.
      }
    }
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

    final normalized = mimeType?.trim().toLowerCase();
    if (normalized == 'image/heic' || normalized == 'image/heif') {
      return _generateHeicOrHeifThumbnail(rawMediaBytes);
    }

    return _vaultEncryption.generateThumbnail(rawMediaBytes);
  }

  /// HEIC/HEIF decoding requires Flutter's engine codec (main isolate only).
  Future<Uint8List> _generateHeicOrHeifThumbnail(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 320);
    final frame = await codec.getNextFrame();
    try {
      final pngData = await frame.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (pngData == null) {
        return Uint8List(0);
      }
      final decoded = img.decodeImage(pngData.buffer.asUint8List());
      if (decoded == null) {
        return Uint8List(0);
      }
      return Uint8List.fromList(img.encodeJpg(decoded, quality: 72));
    } finally {
      frame.image.dispose();
    }
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
      assetFingerprint: assetFingerprint,
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
    await getIt<KeyCustodyService>().purgeAllLocalKeys();
  }

  /// Ensures the archive AES key exists in secure storage (creates if absent).
  Future<void> ensureVaultKey() async {
    await _loadOrCreateKeyBytes();
  }

  /// Re-reads sovereign archive key from secure storage after restore.
  Future<void> reloadVaultKey() async {
    await _secureStorage.read(key: _vaultKeyName);
  }

  /// Removes the local SQLite row and encrypted + thumbnail files for one asset.
  ///
  /// Does **not** delete remote `proof_ledger` / chain artifacts; those may
  /// remain as historical records on Supabase.
  Future<void> deleteArchiveItem(String assetFingerprint) async {
    getIt<IsolateLockCoordinator>().unlock(assetFingerprint);

    final item = await _database.findArchiveItem(assetFingerprint);
    if (item == null) {
      return;
    }

    final resolved = await _pathResolver.resolve(item);
    final transactionalPaths =
        await _storage.resolveTransactionalPaths(assetFingerprint);
    await _storage.purgePaths([
      resolved.encryptedPath,
      resolved.thumbnailPath,
      ...transactionalPaths.pathsForPurge,
    ]);

    try {
      final journal = getIt<JournalRepository>();
      if (journal.isAvailable) {
        await journal.open();
        journal.purgeAsset(assetFingerprint);
      }
    } catch (_) {}

    await _database.deleteArchiveItem(assetFingerprint);
  }

  /// Background-friendly: `seal_ledger` active-wallet row + proof ledger completion.
  /// Returns `true` if [pending_sync] was cleared for this asset.
  Future<bool> retryPendingRemoteSync(String assetFingerprint) async {
    if (AppConfig.usePolygonNotarizer) {
      return _retryPendingPolygonSync(assetFingerprint);
    }
    return _retryPendingSimulatedSync(assetFingerprint);
  }

  static const _pendingSyncNetworkTimeout = Duration(seconds: 15);

  Future<bool> _retryPendingPolygonSync(String assetFingerprint) async {
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
      await _sealLedgerRepository
          .syncAssetFingerprint(assetFingerprint)
          .timeout(_pendingSyncNetworkTimeout);
    } on TimeoutException {
      await _database.markSyncDeferred(
        assetFingerprint: assetFingerprint,
        nextRetryAt: _nextRetryAt(item.syncAttemptCount + 1),
      );
      return false;
    } catch (_) {}

    try {
      final remoteStatus = await _sealLedgerRepository
          .fetchProofNotarizationStatus(assetFingerprint)
          .timeout(_pendingSyncNetworkTimeout);
      if (remoteStatus == 'notarized') {
        final chainTxHash = await _sealLedgerRepository.fetchProofChainTxHash(
          assetFingerprint,
        );
        await _finalizeLocalPolygonSync(
          assetFingerprint,
          chainTxHash: chainTxHash,
        );
        return true;
      }
    } catch (e) {
      if (!_isRecoverableRemoteFailure(e)) {
        return false;
      }
    }

    String? deviceSignature;
    String? ownerSignature;
    try {
      deviceSignature = await _nativeEnclave.signHash(assetFingerprint);
      ownerSignature = await _walletService.signMessageHash(assetFingerprint);
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

    String? chainTxHash;
    try {
      chainTxHash = await _dispatchPolygonRelay(
        fileHash: assetFingerprint,
        ownerSignature: ownerSignature,
        deviceSignature: deviceSignature,
      );
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
    if (chainTxHash != null) {
      return true;
    }

    await _database.markSyncDeferred(
      assetFingerprint: assetFingerprint,
      nextRetryAt: _nextRetryAt(item.syncAttemptCount + 1),
    );
    return false;
  }

  Future<bool> _retryPendingSimulatedSync(String assetFingerprint) async {
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
      await _database.markSyncSucceeded(
        assetFingerprint: assetFingerprint,
        chainTxHash: chainTxHash,
      );
      return true;
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        await _database.markSyncSucceeded(
          assetFingerprint: assetFingerprint,
          chainTxHash: chainTxHash,
        );
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

  Future<void> _attemptCloudVaultSync({
    required String? sourcePath,
    required String fileHash,
    required String mimeType,
    required String userId,
  }) async {
    final coordinator = _vaultSyncCoordinator;
    if (coordinator == null) {
      return;
    }
    final path = sourcePath?.trim();
    if (path == null || path.isEmpty) {
      return;
    }

    try {
      final keyBytes = await _loadOrCreateKeyBytes();
      final encodedVaultKey = _vaultEncryption.encodeKey(keyBytes);
      await coordinator.syncAfterNotarization(
        rawSourceFile: File(path),
        assetHash: fileHash,
        mimeType: mimeType,
        userId: userId,
        encodedVaultKey: encodedVaultKey,
        cloudSealPassword: encodedVaultKey,
      );
    } catch (_) {
      // Cloud vault sync is best-effort; local seal + ledger state must not roll back.
    }
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
