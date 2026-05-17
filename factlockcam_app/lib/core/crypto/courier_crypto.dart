import 'dart:typed_data';

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
    if (verifiedFingerprint != expectedFingerprint) {
      throw StateError('Sealed media failed SHA-256 verification.');
    }
    return clearBytes;
  }
}
