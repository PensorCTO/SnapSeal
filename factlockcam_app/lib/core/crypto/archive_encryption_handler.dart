import 'dart:typed_data';

import 'cipher_engine.dart';

/// Local vault crypto façade over [CipherEngine] (AES-GCM + SHA-256 today).
///
/// **Inputs:** plaintext or ciphertext [Uint8List], 32-byte vault key material.
/// **Outputs:** AES-GCM sealed payloads (nonce || MAC || ciphertext), SHA-256 hex
/// digests, JPEG thumbnails for raster image payloads.
/// **Expected failure modes:**
/// - Decryption/authentication failure from wrong key or truncated/corrupt blob
///   (surfaced by the underlying `cryptography` package).
/// - Empty thumbnail when bytes are not decodable as a supported image format.
abstract class ArchiveEncryptionHandler {
  Future<String> generateHash(Uint8List bytes);

  Future<Uint8List> encrypt({
    required Uint8List bytes,
    required Uint8List keyBytes,
  });

  Future<Uint8List> decrypt({
    required Uint8List encryptedPayload,
    required Uint8List keyBytes,
  });

  Future<Uint8List> generateThumbnail(Uint8List bytes);

  Uint8List generateKeyBytes();

  String encodeKey(Uint8List keyBytes);

  Uint8List decodeKey(String encodedKey);
}

/// Default implementation delegating to [CipherEngine] (isolate-backed where applicable).
class DefaultArchiveEncryptionHandler implements ArchiveEncryptionHandler {
  @override
  Future<String> generateHash(Uint8List bytes) =>
      CipherEngine.generateHash(bytes);

  @override
  Future<Uint8List> encrypt({
    required Uint8List bytes,
    required Uint8List keyBytes,
  }) => CipherEngine.encrypt(bytes: bytes, keyBytes: keyBytes);

  @override
  Future<Uint8List> decrypt({
    required Uint8List encryptedPayload,
    required Uint8List keyBytes,
  }) => CipherEngine.decrypt(
    encryptedPayload: encryptedPayload,
    keyBytes: keyBytes,
  );

  @override
  Future<Uint8List> generateThumbnail(Uint8List bytes) =>
      CipherEngine.generateThumbnail(bytes);

  @override
  Uint8List generateKeyBytes() => CipherEngine.generateKeyBytes();

  @override
  String encodeKey(Uint8List keyBytes) => CipherEngine.encodeKey(keyBytes);

  @override
  Uint8List decodeKey(String encodedKey) => CipherEngine.decodeKey(encodedKey);
}
