/// Web stub — hardware attestation is unavailable in browser environments.
class NativeEnclaveChannel {
  NativeEnclaveChannel({
    Object? channel,
    Future<String> Function(String hash)? signHashForTests,
  });

  Future<String> signHash(String hash) async {
    throw UnsupportedError(
      'Hardware attestation is not available on web. '
      'Capture and enclave signing require the native application.',
    );
  }
}
