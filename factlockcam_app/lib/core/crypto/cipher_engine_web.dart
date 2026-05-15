import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:image/image.dart' as image;

class CipherEngine {
  static const keyLength = 32;
  static const nonceLength = 12;
  static const macLength = 16;

  static Future<String> generateHash(Uint8List bytes) async {
    return crypto.sha256.convert(bytes).toString();
  }

  static Future<Uint8List> encrypt({
    required Uint8List bytes,
    required Uint8List keyBytes,
  }) {
    return _encrypt(bytes: bytes, keyBytes: keyBytes);
  }

  static Future<Uint8List> decrypt({
    required Uint8List encryptedPayload,
    required Uint8List keyBytes,
  }) {
    return _decrypt(encryptedPayload: encryptedPayload, keyBytes: keyBytes);
  }

  static Future<Uint8List> generateThumbnail(Uint8List bytes) async {
    final decoded = image.decodeImage(bytes);
    if (decoded == null) {
      return Uint8List(0);
    }

    final thumbnail = image.copyResize(decoded, width: 320);
    return Uint8List.fromList(image.encodeJpg(thumbnail, quality: 72));
  }

  static Uint8List generateKeyBytes() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(keyLength, (_) => random.nextInt(256)),
    );
  }

  static String encodeKey(Uint8List keyBytes) => base64Encode(keyBytes);

  static Uint8List decodeKey(String encodedKey) => base64Decode(encodedKey);

  static Future<Uint8List> _encrypt({
    required Uint8List bytes,
    required Uint8List keyBytes,
  }) async {
    final algorithm = AesGcm.with256bits();
    final secretBox = await algorithm.encrypt(
      bytes,
      secretKey: SecretKey(keyBytes),
    );

    return Uint8List.fromList([
      ...secretBox.nonce,
      ...secretBox.mac.bytes,
      ...secretBox.cipherText,
    ]);
  }

  static Future<Uint8List> _decrypt({
    required Uint8List encryptedPayload,
    required Uint8List keyBytes,
  }) async {
    final nonce = encryptedPayload.sublist(0, nonceLength);
    final mac = encryptedPayload.sublist(nonceLength, nonceLength + macLength);
    final cipherText = encryptedPayload.sublist(nonceLength + macLength);

    final algorithm = AesGcm.with256bits();
    final clearBytes = await algorithm.decrypt(
      SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
      secretKey: SecretKey(keyBytes),
    );

    return Uint8List.fromList(clearBytes);
  }
}
