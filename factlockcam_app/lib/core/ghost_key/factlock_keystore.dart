import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';

/// Password-encrypted `.factlock` envelope for composite sovereign key payloads.
class FactlockKeystore {
  static const defaultIterations = 100000;
  static const envelopeVersion = 1;
  static const innerPayloadVersion = 1;

  /// Builds the inner composite JSON map (plaintext, pre-encryption).
  static Map<String, dynamic> buildInnerPayload({
    required String evmPrivateKeyHex,
    required String vaultAesKeyEncoded,
  }) {
    return {
      'version': innerPayloadVersion,
      'evm_key': evmPrivateKeyHex,
      'vault_key': vaultAesKeyEncoded,
    };
  }

  Future<Map<String, dynamic>> encryptInnerPayload({
    required Map<String, dynamic> innerPayload,
    required String password,
    int iterations = defaultIterations,
  }) async {
    final innerJson = jsonEncode(innerPayload);
    return Isolate.run(
      () async => _encryptPayload(
        password: password,
        innerJson: innerJson,
        iterations: iterations,
      ),
    );
  }

  Future<Map<String, dynamic>> decryptEnvelope({
    required Map<String, dynamic> envelope,
    required String password,
  }) async {
    return Isolate.run(
      () async => _decryptPayload(envelope: envelope, password: password),
    );
  }

  /// Validates decrypted inner payload fields.
  static void validateInnerPayload(Map<String, dynamic> payload) {
    if (payload['version'] != innerPayloadVersion) {
      throw FormatException(
        'Unsupported inner payload version: ${payload['version']}',
      );
    }
    final evmKey = payload['evm_key'];
    final vaultKey = payload['vault_key'];
    if (evmKey is! String || evmKey.isEmpty) {
      throw FormatException('Missing or invalid evm_key in backup payload.');
    }
    if (vaultKey is! String || vaultKey.isEmpty) {
      throw FormatException('Missing or invalid vault_key in backup payload.');
    }
    var normalizedEvm = evmKey.trim().toLowerCase();
    if (normalizedEvm.startsWith('0x')) {
      normalizedEvm = normalizedEvm.substring(2);
    }
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(normalizedEvm)) {
      throw FormatException('evm_key is not a valid 32-byte hex private key.');
    }
    try {
      final vaultBytes = base64Decode(vaultKey);
      if (vaultBytes.length != 32) {
        throw FormatException('vault_key must decode to 32 bytes.');
      }
    } catch (error) {
      if (error is FormatException) rethrow;
      throw FormatException('vault_key is not valid base64: $error');
    }
  }

  static Map<String, dynamic> parseEnvelopeJson(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('.factlock envelope must be a JSON object.');
    }
    if (decoded['version'] != envelopeVersion) {
      throw FormatException(
        'Unsupported .factlock envelope version: ${decoded['version']}',
      );
    }
    if (decoded['kdf'] != 'pbkdf2') {
      throw FormatException('Unsupported KDF: ${decoded['kdf']}');
    }
    for (final field in ['salt', 'iv', 'ciphertext', 'mac', 'iterations']) {
      if (!decoded.containsKey(field)) {
        throw FormatException('Missing required envelope field: $field');
      }
    }
    return decoded;
  }
}

Future<Map<String, dynamic>> _encryptPayload({
  required String password,
  required String innerJson,
  required int iterations,
}) async {
  final salt = _randomBytes(16);
  final iv = _randomBytes(12);
  final derived = await _deriveKeyMaterial(
    password: password,
    salt: salt,
    iterations: iterations,
  );
  final encKey = derived.sublist(0, 32);
  final macKey = derived.sublist(32, 64);

  final cipherText = await _aesGcmEncrypt(
    plainText: utf8.encode(innerJson),
    key: encKey,
    iv: iv,
  );

  final mac = crypto.Hmac(crypto.sha256, macKey).convert([
    ...salt,
    ...iv,
    ...cipherText,
  ]).bytes;

  return {
    'version': FactlockKeystore.envelopeVersion,
    'kdf': 'pbkdf2',
    'iterations': iterations,
    'salt': _bytesToHex(salt),
    'iv': _bytesToHex(iv),
    'ciphertext': _bytesToHex(cipherText),
    'mac': _bytesToHex(mac),
  };
}

Future<Map<String, dynamic>> _decryptPayload({
  required Map<String, dynamic> envelope,
  required String password,
}) async {
  final iterations = envelope['iterations'] as int;
  final salt = _hexToBytes(envelope['salt'] as String);
  final iv = _hexToBytes(envelope['iv'] as String);
  final cipherText = _hexToBytes(envelope['ciphertext'] as String);
  final expectedMac = _hexToBytes(envelope['mac'] as String);

  final derived = await _deriveKeyMaterial(
    password: password,
    salt: salt,
    iterations: iterations,
  );
  final encKey = derived.sublist(0, 32);
  final macKey = derived.sublist(32, 64);

  final actualMac = crypto.Hmac(crypto.sha256, macKey).convert([
    ...salt,
    ...iv,
    ...cipherText,
  ]).bytes;

  if (!_constantTimeEquals(actualMac, expectedMac)) {
    throw StateError(
      'Backup password incorrect or file is corrupt (MAC mismatch).',
    );
  }

  final clearBytes = await _aesGcmDecrypt(
    cipherText: cipherText,
    key: encKey,
    iv: iv,
  );
  final innerJson = utf8.decode(clearBytes);
  final decoded = jsonDecode(innerJson);
  if (decoded is! Map<String, dynamic>) {
    throw FormatException('Decrypted payload is not a JSON object.');
  }
  FactlockKeystore.validateInnerPayload(decoded);
  return decoded;
}

Future<Uint8List> _deriveKeyMaterial({
  required String password,
  required List<int> salt,
  required int iterations,
}) async {
  final pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: iterations,
    bits: 512,
  );
  final secretKey = await pbkdf2.deriveKey(
    secretKey: SecretKey(utf8.encode(password)),
    nonce: salt,
  );
  return Uint8List.fromList(await secretKey.extractBytes());
}

Future<Uint8List> _aesGcmEncrypt({
  required List<int> plainText,
  required List<int> key,
  required List<int> iv,
}) async {
  final algorithm = AesGcm.with256bits();
  final secretBox = await algorithm.encrypt(
    plainText,
    secretKey: SecretKey(key),
    nonce: iv,
  );
  return Uint8List.fromList([...secretBox.cipherText, ...secretBox.mac.bytes]);
}

Future<Uint8List> _aesGcmDecrypt({
  required List<int> cipherText,
  required List<int> key,
  required List<int> iv,
}) async {
  if (cipherText.length < 16) {
    throw FormatException('Ciphertext too short for AES-GCM.');
  }
  final macBytes = cipherText.sublist(cipherText.length - 16);
  final rawCipher = cipherText.sublist(0, cipherText.length - 16);
  final algorithm = AesGcm.with256bits();
  final clearBytes = await algorithm.decrypt(
    SecretBox(rawCipher, nonce: iv, mac: Mac(macBytes)),
    secretKey: SecretKey(key),
  );
  return Uint8List.fromList(clearBytes);
}

List<int> _randomBytes(int length) {
  final random = Random.secure();
  return List<int>.generate(length, (_) => random.nextInt(256));
}

String _bytesToHex(List<int> bytes) {
  final buffer = StringBuffer();
  for (final byte in bytes) {
    buffer.write(byte.toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}

List<int> _hexToBytes(String hex) {
  final normalized = hex.trim().toLowerCase();
  if (normalized.length.isOdd) {
    throw FormatException('Invalid hex string length.');
  }
  return List<int>.generate(normalized.length ~/ 2, (index) {
    final byte = normalized.substring(index * 2, index * 2 + 2);
    return int.parse(byte, radix: 16);
  });
}

bool _constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}
