import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

import 'vault_encryption_handler.dart';

/// Courier export path: decrypt vault ciphertext and verify it matches the
/// stored SHA-256 fingerprint before releasing plaintext for packaging.
///
/// **Inputs:** sealed payload bytes, vault key, expected fingerprint string (hex).
/// **Outputs:** verified plaintext suitable for outbound packaging.
/// **Expected failure modes:**
/// - **Authentication/decrypt failure** — wrong key, corrupt ciphertext, or
///   truncated payload (errors from the underlying cipher implementation).
/// - **Digest mismatch** — plaintext hash does not equal [expectedFingerprint]
///   ([StateError]; treat as tampering or wrong asset binding).
class CourierCrypto {
  /// Client-side AES-GCM seal before any cloud upload (zero-knowledge).
  ///
  /// **Inputs:** plaintext bytes, password string (SHA-256 derived to 32-byte key).
  /// **Outputs:** nonce || MAC || ciphertext suitable for Supabase Storage upload.
  /// **Expected failure modes:** cipher errors from corrupt inputs or platform crypto failure.
  static Future<Uint8List> encrypt(
    Uint8List plaintext,
    String password, {
    VaultEncryptionHandler? vault,
  }) async {
    final handler = vault ?? DefaultVaultEncryptionHandler();
    final keyBytes = Uint8List.fromList(
      crypto.sha256.convert(utf8.encode(password)).bytes,
    );
    return handler.encrypt(bytes: plaintext, keyBytes: keyBytes);
  }

  static Future<Uint8List> decryptAndVerifyFingerprint({
    required VaultEncryptionHandler vault,
    required Uint8List encryptedPayload,
    required Uint8List keyBytes,
    required String expectedFingerprint,
  }) async {
    final clearBytes = await vault.decrypt(
      encryptedPayload: encryptedPayload,
      keyBytes: keyBytes,
    );
    final verifiedFingerprint = await vault.generateHash(clearBytes);
    final expected = expectedFingerprint.trim().toLowerCase();
    if (verifiedFingerprint.toLowerCase() != expected) {
      throw StateError('Sealed media failed SHA-256 verification.');
    }
    return clearBytes;
  }
}
