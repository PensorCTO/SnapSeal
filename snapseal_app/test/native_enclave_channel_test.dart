import 'package:flutter_test/flutter_test.dart';
import 'package:snapseal/core/ghost_key/native_enclave_channel.dart';

void main() {
  test(
    'signHash uses signHashForTests when provided (no platform channel)',
    () async {
      final channel = NativeEnclaveChannel(
        signHashForTests: (hash) async => 'injected:$hash',
      );
      expect(await channel.signHash('deadbeef'), 'injected:deadbeef');
    },
  );
}
