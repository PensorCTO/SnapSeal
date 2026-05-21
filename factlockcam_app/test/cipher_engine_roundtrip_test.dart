import 'dart:typed_data';

import 'package:factlockcam/core/crypto/courier_crypto.dart';
import 'package:factlockcam/core/crypto/vault_encryption_handler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('encrypt/decrypt round-trip preserves plaintext and hash', () async {
    final vault = DefaultVaultEncryptionHandler();
    final keyBytes = vault.generateKeyBytes();
    final plaintext = Uint8List.fromList(List<int>.generate(4096, (i) => i % 251));

    final digest = await vault.generateHash(plaintext);
    final encrypted = await vault.encrypt(bytes: plaintext, keyBytes: keyBytes);
    expect(encrypted.length, greaterThan(plaintext.length));

    final verified = await CourierCrypto.decryptAndVerifyFingerprint(
      vault: vault,
      encryptedPayload: encrypted,
      keyBytes: keyBytes,
      expectedFingerprint: digest,
    );

    expect(verified, plaintext);
  });
}
