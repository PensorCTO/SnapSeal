// ignore_for_file: avoid_web_libraries_in_flutter, avoid_dynamic_calls

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'dart:html' as html;

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:image/image.dart' as image;

/// Browser-aware [CipherEngine] that prefers the Web Crypto API and Canvas API
/// over pure-Dart implementations where they would block the UI thread.
///
/// **Platform note:** [Isolate.run] is unavailable on the web. This class uses
/// the browser's built-in SubtleCrypto for SHA-256 and AES-GCM, and off-screen
/// Canvas elements for thumbnail generation. All of these are truly
/// asynchronous and hardware-accelerated in modern browsers — they do not
/// block the Flutter UI thread.
///
/// Falls back to pure-Dart `package:crypto` / `package:image` when browser
/// APIs are unavailable (e.g. insecure HTTP context).
class CipherEngine {
  static const keyLength = 32;
  static const nonceLength = 12;
  static const macLength = 16;

  // ---------------------------------------------------------------------------
  // Hash
  // ---------------------------------------------------------------------------

  /// SHA-256 via browser SubtleCrypto when available, otherwise pure Dart.
  static Future<String> generateHash(Uint8List bytes) async {
    final subtle = html.window.crypto?.subtle;
    if (subtle == null) {
      return _dartSha256(bytes);
    }
    try {
      final buffer = await (subtle as dynamic).digest('SHA-256', bytes.buffer);
      final hashBytes = (buffer as ByteBuffer).asUint8List();
      return hashBytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
    } catch (_) {
      return _dartSha256(bytes);
    }
  }

  // ---------------------------------------------------------------------------
  // AES-GCM (uses package:cryptography — async on all platforms)
  // ---------------------------------------------------------------------------

  /// AES-GCM encrypt.  The underlying `package:cryptography` implementation
  /// is asynchronous on both native and web, so this call does **not** block
  /// the UI thread.
  ///
  /// Returns `nonce || mac || ciphertext`, matching the IO layout.
  static Future<Uint8List> encrypt({
    required Uint8List bytes,
    required Uint8List keyBytes,
  }) {
    return _encrypt(bytes: bytes, keyBytes: keyBytes);
  }

  /// AES-GCM decrypt.  Async-safe for the same reason as [encrypt].
  static Future<Uint8List> decrypt({
    required Uint8List encryptedPayload,
    required Uint8List keyBytes,
  }) {
    return _decrypt(encryptedPayload: encryptedPayload, keyBytes: keyBytes);
  }

  // ---------------------------------------------------------------------------
  // Thumbnail
  // ---------------------------------------------------------------------------

  /// Generates a 320 px-wide JPEG thumbnail.
  ///
  /// On the web this uses an off-screen [html.CanvasElement] (browser-native
  /// image codec + hardware-accelerated scaling) so no Dart-side pixel work
  /// blocks the UI thread.  Falls back to pure-Dart `package:image` when the
  /// Canvas approach fails or is unavailable.
  static Future<Uint8List> generateThumbnail(Uint8List bytes) async {
    try {
      final blob = html.Blob([bytes.buffer]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Load image off-screen — this is a truly async browser decode.
      final img = html.ImageElement(src: url);
      await img.onLoad.first.timeout(const Duration(seconds: 10));
      html.Url.revokeObjectUrl(url);

      if (img.naturalWidth == 0 || img.naturalHeight == 0) {
        return Uint8List(0);
      }

      final w = 320;
      final h =
          (w / img.naturalWidth * img.naturalHeight).round().clamp(1, 4320);
      if (h <= 0) {
        return Uint8List(0);
      }

      final canvas = html.CanvasElement(width: w, height: h);
      canvas.context2D.drawImageScaled(img, 0, 0, w, h);

      final jpegBlob = await _canvasToBlob(canvas, 'image/jpeg', 0.72);
      if (jpegBlob == null) {
        return Uint8List(0);
      }

      return await _readBlobAsBytes(jpegBlob);
    } catch (_) {
      return _dartThumbnail(bytes);
    }
  }

  // ---------------------------------------------------------------------------
  // Key helpers (pure Dart, fast)
  // ---------------------------------------------------------------------------

  static Uint8List generateKeyBytes() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(keyLength, (_) => random.nextInt(256)),
    );
  }

  static String encodeKey(Uint8List keyBytes) => base64Encode(keyBytes);

  static Uint8List decodeKey(String encodedKey) => base64Decode(encodedKey);

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static String _dartSha256(Uint8List bytes) {
    return crypto.sha256.convert(bytes).toString();
  }

  static Uint8List _dartThumbnail(Uint8List bytes) {
    final decoded = image.decodeImage(bytes);
    if (decoded == null) return Uint8List(0);
    final thumbnail = image.copyResize(decoded, width: 320);
    return Uint8List.fromList(image.encodeJpg(thumbnail, quality: 72));
  }

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

  /// Wraps the callback-based `CanvasElement.toBlob` in a [Future].
  static Future<html.Blob?> _canvasToBlob(
    html.CanvasElement canvas,
    String mimeType,
    double quality,
  ) {
    final completer = Completer<html.Blob?>();
    // dart:html's toBlob signature varies across SDK versions; the dynamic
    // path keeps this working at runtime regardless of the static type.
    (canvas as dynamic).toBlob(
      (dynamic blob) => completer.complete(blob as html.Blob?),
      mimeType,
      quality,
    );
    return completer.future;
  }

  /// Reads a [html.Blob] into a [Uint8List] via [html.FileReader].
  static Future<Uint8List> _readBlobAsBytes(html.Blob blob) async {
    final reader = html.FileReader();
    reader.readAsArrayBuffer(blob);
    await reader.onLoad.first;
    final buffer = reader.result as ByteBuffer?;
    return buffer?.asUint8List() ?? Uint8List(0);
  }
}
