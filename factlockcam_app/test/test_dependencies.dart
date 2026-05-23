import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:factlockcam/core/di/injection.dart';

Directory? _testDocumentsDirectory;

/// Satisfies the DI graph for widget smoke tests without native platform channels.
///
/// Mocks [path_provider] and [shared_preferences] channels, then registers app
/// singletons via [configureDependencies].
Future<void> setupTestDependencies() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  _testDocumentsDirectory ??= await Directory.systemTemp.createTemp(
    'factlockcam_widget_test_',
  );

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(pathProviderChannel, (call) async {
        switch (call.method) {
          case 'getApplicationDocumentsDirectory':
          case 'getApplicationSupportDirectory':
          case 'getLibraryDirectory':
            return _testDocumentsDirectory!.path;
          case 'getTemporaryDirectory':
            return p.join(_testDocumentsDirectory!.path, 'tmp');
          case 'getDownloadsDirectory':
            return p.join(_testDocumentsDirectory!.path, 'downloads');
          default:
            return _testDocumentsDirectory!.path;
        }
      });

  const sharedPreferencesChannel = MethodChannel(
    'plugins.flutter.io/shared_preferences',
  );
  final preferencesStore = <String, Object>{};
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(sharedPreferencesChannel, (call) async {
        switch (call.method) {
          case 'getAll':
            return Map<String, Object>.from(preferencesStore);
          case 'setBool':
            preferencesStore[call.arguments['key'] as String] =
                call.arguments['value'] as bool;
            return true;
          case 'setInt':
            preferencesStore[call.arguments['key'] as String] =
                call.arguments['value'] as int;
            return true;
          case 'setDouble':
            preferencesStore[call.arguments['key'] as String] =
                call.arguments['value'] as double;
            return true;
          case 'setString':
            preferencesStore[call.arguments['key'] as String] =
                call.arguments['value'] as String;
            return true;
          case 'setStringList':
            preferencesStore[call.arguments['key'] as String] =
                List<String>.from(call.arguments['value'] as List<dynamic>);
            return true;
          case 'remove':
            preferencesStore.remove(call.arguments['key'] as String);
            return true;
          case 'clear':
            preferencesStore.clear();
            return true;
          default:
            return null;
        }
      });

  await resetDependenciesForTest();
  await configureDependencies();
}
