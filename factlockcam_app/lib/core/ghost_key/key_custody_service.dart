import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'key_storage_keys.dart';

/// Read, write, purge, and presence checks for both sovereign secure-storage keys.
class KeyCustodyService {
  KeyCustodyService({required FlutterSecureStorage secureStorage})
      : _secureStorage = secureStorage;

  static const _maxDeleteAttempts = 3;

  final FlutterSecureStorage _secureStorage;

  Future<String?> readEvmPrivateKeyHex() =>
      _secureStorage.read(key: KeyStorageKeys.evmPrivateKey);

  Future<String?> readVaultAesKeyEncoded() =>
      _secureStorage.read(key: KeyStorageKeys.vaultAesKey);

  Future<bool> hasLocalKeys() async {
    final evm = await readEvmPrivateKeyHex();
    final vault = await readVaultAesKeyEncoded();
    return _isNonEmpty(evm) && _isNonEmpty(vault);
  }

  Future<void> rehydrateKeys({
    required String evmPrivateKeyHex,
    required String vaultAesKeyEncoded,
  }) async {
    await Future.wait([
      _secureStorage.write(
        key: KeyStorageKeys.evmPrivateKey,
        value: evmPrivateKeyHex,
      ),
      _secureStorage.write(
        key: KeyStorageKeys.vaultAesKey,
        value: vaultAesKeyEncoded,
      ),
    ]);
  }

  /// Deletes both sovereign keys with retry-on-failure semantics.
  Future<void> purgeAllLocalKeys() async {
    await _deleteWithRetry(KeyStorageKeys.evmPrivateKey);
    await _deleteWithRetry(KeyStorageKeys.vaultAesKey);
    await _deleteWithRetry(KeyStorageKeys.legacyVaultAesKey);

    if (!await _keysConfirmedAbsent()) {
      throw StateError(
        'Local sovereign keys could not be fully purged from secure storage.',
      );
    }
  }

  Future<void> purgeSovereignKeysOnly() async {
    await purgeAllLocalKeys();
  }

  Future<void> _deleteWithRetry(String key) async {
    Object? lastError;
    for (var attempt = 0; attempt < _maxDeleteAttempts; attempt++) {
      try {
        await _secureStorage.delete(key: key);
        final remaining = await _secureStorage.read(key: key);
        if (!_isNonEmpty(remaining)) {
          return;
        }
      } catch (error) {
        lastError = error;
      }
    }
    if (lastError != null) {
      throw StateError('Failed to delete secure storage key "$key": $lastError');
    }
  }

  Future<bool> _keysConfirmedAbsent() async {
    final evm = await readEvmPrivateKeyHex();
    final vault = await readVaultAesKeyEncoded();
    return !_isNonEmpty(evm) && !_isNonEmpty(vault);
  }

  bool _isNonEmpty(String? value) => value != null && value.isNotEmpty;
}
