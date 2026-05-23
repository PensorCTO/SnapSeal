import 'dart:io' show Platform;

bool get isRunningFlutterTest => Platform.environment['FLUTTER_TEST'] == 'true';
