import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'backup_metadata_store.dart';
import 'factlock_keystore.dart';
import 'key_custody_service.dart';

/// Exports and imports password-encrypted `.factlock` sovereign key bundles.
class WalletBackupService {
  WalletBackupService({
    required KeyCustodyService keyCustodyService,
    required FactlockKeystore keystore,
    required BackupMetadataStore backupMetadataStore,
  })  : _keyCustodyService = keyCustodyService,
        _keystore = keystore,
        _backupMetadataStore = backupMetadataStore;

  final KeyCustodyService _keyCustodyService;
  final FactlockKeystore _keystore;
  final BackupMetadataStore _backupMetadataStore;

  /// Reads both keys, encrypts composite payload, writes temp `.factlock` file.
  Future<File> exportFactlock({required String backupPassword}) async {
    if (backupPassword.length < 8) {
      throw ArgumentError('Backup password must be at least 8 characters.');
    }

    final evmKey = await _keyCustodyService.readEvmPrivateKeyHex();
    final vaultKey = await _keyCustodyService.readVaultAesKeyEncoded();
    if (evmKey == null ||
        evmKey.isEmpty ||
        vaultKey == null ||
        vaultKey.isEmpty) {
      throw StateError(
        'Cannot export: sovereign keys are not present on this device.',
      );
    }

    final innerPayload = FactlockKeystore.buildInnerPayload(
      evmPrivateKeyHex: evmKey,
      vaultAesKeyEncoded: vaultKey,
    );
    final envelope = await _keystore.encryptInnerPayload(
      innerPayload: innerPayload,
      password: backupPassword,
    );

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final file = File('${tempDir.path}/archive_backup_$timestamp.factlock');
    await file.writeAsString(jsonEncode(envelope));

    await _backupMetadataStore.markBackupCompleted();
    return file;
  }

  /// Decrypts envelope bytes and rehydrates both sovereign keys.
  Future<void> importFactlock({
    required List<int> fileBytes,
    required String backupPassword,
  }) async {
    final raw = utf8.decode(fileBytes);
    final envelope = FactlockKeystore.parseEnvelopeJson(raw);
    final innerPayload = await _keystore.decryptEnvelope(
      envelope: envelope,
      password: backupPassword,
    );

    await _keyCustodyService.rehydrateKeys(
      evmPrivateKeyHex: innerPayload['evm_key'] as String,
      vaultAesKeyEncoded: innerPayload['vault_key'] as String,
    );
  }
}
