import 'dart:isolate';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/crypto/cipher_engine.dart';
import '../../data/local/vault_database.dart';
import '../../data/models/archive_item.dart';
import '../../data/models/sealed_asset.dart';
import '../../data/services/local_vault_storage.dart';
import '../../data/supabase/seal_ledger_repository.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final vaultServiceProvider = Provider<VaultService>(
  (ref) => VaultService(
    database: ref.watch(vaultDatabaseProvider),
    storage: ref.watch(localVaultStorageProvider),
    secureStorage: ref.watch(secureStorageProvider),
    sealLedgerRepository: ref.watch(sealLedgerRepositoryProvider),
  ),
);

class SealCaptureResult {
  const SealCaptureResult({
    required this.assetFingerprint,
    required this.pendingSync,
  });

  final String assetFingerprint;
  final bool pendingSync;
}

class VaultService {
  VaultService({
    required VaultDatabase database,
    required LocalVaultStorage storage,
    required FlutterSecureStorage secureStorage,
    required SealLedgerRepository sealLedgerRepository,
  }) : _database = database,
       _storage = storage,
       _secureStorage = secureStorage,
       _sealLedgerRepository = sealLedgerRepository;

  static const _vaultKeyName = 'snapseal:vault_key';

  final VaultDatabase _database;
  final LocalVaultStorage _storage;
  final FlutterSecureStorage _secureStorage;
  final SealLedgerRepository _sealLedgerRepository;

  Future<String> sealAndStore(
    Uint8List rawMediaBytes, {
    String? mimeType,
  }) async {
    final result = await _sealAndStoreBytes(rawMediaBytes, mimeType: mimeType);
    return result.assetFingerprint;
  }

  Future<SealCaptureResult> sealAndStoreCapture(XFile capturedFile) async {
    final rawMediaBytes = await Isolate.run(
      () => File(capturedFile.path).readAsBytesSync(),
    );
    final mimeType = _inferMimeType(capturedFile.path);
    return _sealAndStoreBytes(rawMediaBytes, mimeType: mimeType);
  }

  Future<SealCaptureResult> _sealAndStoreBytes(
    Uint8List rawMediaBytes, {
    String? mimeType,
  }) async {
    final assetFingerprint = await CipherEngine.generateHash(rawMediaBytes);
    final keyBytes = await _loadOrCreateKeyBytes();
    final encryptedBytes = await CipherEngine.encrypt(
      bytes: rawMediaBytes,
      keyBytes: keyBytes,
    );
    final thumbnailBytes = await CipherEngine.generateThumbnail(rawMediaBytes);

    final encryptedPath = await _storage.writeEncryptedOriginal(
      assetFingerprint: assetFingerprint,
      bytes: encryptedBytes,
    );
    final thumbnailPath = await _storage.writeThumbnail(
      assetFingerprint: assetFingerprint,
      bytes: thumbnailBytes,
    );

    await _database.upsertArchiveItem(
      ArchiveItem(
        assetFingerprint: assetFingerprint,
        encryptedPath: encryptedPath,
        thumbnailPath: thumbnailPath,
        byteLength: rawMediaBytes.length,
        mimeType: mimeType,
        createdAt: DateTime.now().toUtc(),
        pendingSync: true,
      ),
    );

    var pendingSync = true;
    if (_sealLedgerRepository.isConfigured) {
      try {
        await _sealLedgerRepository.syncAssetFingerprint(assetFingerprint);
        pendingSync = false;
      } catch (_) {
        pendingSync = true;
      }
    }

    await _database.setPendingSync(
      assetFingerprint: assetFingerprint,
      pendingSync: pendingSync,
    );

    return SealCaptureResult(
      assetFingerprint: assetFingerprint,
      pendingSync: pendingSync,
    );
  }

  Future<SealedAsset> extractForCourier(String assetFingerprint) async {
    final item = await _database.findArchiveItem(assetFingerprint);
    if (item == null) {
      throw StateError('No sealed asset exists for $assetFingerprint.');
    }

    final keyBytes = await _loadOrCreateKeyBytes();
    final encryptedBytes = await _storage.readEncryptedOriginal(
      item.encryptedPath,
    );
    final clearBytes = await CipherEngine.decrypt(
      encryptedPayload: encryptedBytes,
      keyBytes: keyBytes,
    );
    final verifiedFingerprint = await CipherEngine.generateHash(clearBytes);

    if (verifiedFingerprint != assetFingerprint) {
      throw StateError('Sealed media failed SHA-256 verification.');
    }

    return SealedAsset(assetFingerprint: assetFingerprint, bytes: clearBytes);
  }

  Future<void> burnLocalWallet() async {
    await _database.deleteAll();
    await _storage.deleteAll();
    await _secureStorage.delete(key: _vaultKeyName);
  }

  Future<Uint8List> _loadOrCreateKeyBytes() async {
    final existing = await _secureStorage.read(key: _vaultKeyName);
    if (existing != null) {
      return CipherEngine.decodeKey(existing);
    }

    final keyBytes = CipherEngine.generateKeyBytes();
    await _secureStorage.write(
      key: _vaultKeyName,
      value: CipherEngine.encodeKey(keyBytes),
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
}
