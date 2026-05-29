export 'native_enclave_channel_stub.dart'
    if (dart.library.io) 'native_enclave_channel_io.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/locator.dart';
import 'native_enclave_channel_stub.dart'
    if (dart.library.io) 'native_enclave_channel_io.dart';

final nativeEnclaveChannelProvider = Provider<NativeEnclaveChannel>(
  (ref) => getIt<NativeEnclaveChannel>(),
);
