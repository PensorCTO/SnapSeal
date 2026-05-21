import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../di/locator.dart';

/// Hardware-backed signing bridge (Secure Enclave / Android Keystore).
/// Native handlers register `com.factlockcam.app/enclave` and implement `signHash`.
///
/// For widget/unit tests without a platform engine, pass [signHashForTests].
class NativeEnclaveChannel {
  NativeEnclaveChannel({
    MethodChannel? channel,
    Future<String> Function(String hash)? signHashForTests,
  }) : _channel = channel ?? const MethodChannel('com.factlockcam.app/enclave'),
       _signHashForTests = signHashForTests;

  static const String _signMethod = 'signHash';

  final MethodChannel _channel;
  final Future<String> Function(String hash)? _signHashForTests;

  Future<String> signHash(String hash) async {
    final override = _signHashForTests;
    if (override != null) {
      return override(hash);
    }

    final result = await _channel.invokeMethod<dynamic>(_signMethod, hash);
    if (result is! String || result.isEmpty) {
      throw StateError('Native enclave returned an empty signature.');
    }
    return result;
  }
}

final nativeEnclaveChannelProvider = Provider<NativeEnclaveChannel>(
  (ref) => getIt<NativeEnclaveChannel>(),
);
