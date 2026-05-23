import 'runtime_test_flag_stub.dart'
    if (dart.library.io) 'runtime_test_flag_io.dart' as runtime;

/// Whether the current isolate is executing under `flutter test`.
bool get isRunningFlutterTest => runtime.isRunningFlutterTest;
