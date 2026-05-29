import 'package:factlockcam/core/ghost_key/app_lock_coordinator.dart';
import 'package:factlockcam/core/ghost_key/key_custody_service.dart';
import 'package:factlockcam/core/ghost_key/key_storage_keys.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockSecureStorage storage;
  late KeyCustodyService custody;
  late AppLockCoordinator coordinator;
  final store = <String, String>{};

  setUp(() {
    storage = _MockSecureStorage();
    store.clear();
    custody = KeyCustodyService(secureStorage: storage);
    coordinator = AppLockCoordinator(keyCustodyService: custody);

    when(() => storage.read(key: any(named: 'key'))).thenAnswer((invocation) async {
      return store[invocation.namedArguments[#key] as String];
    });
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((invocation) async {
      store.remove(invocation.namedArguments[#key] as String);
    });
  });

  test('lockArchive purges both keys and fails closed if one remains', () async {
    store[KeyStorageKeys.evmPrivateKey] = '0xevm';
    store[KeyStorageKeys.vaultAesKey] = 'vault';

    await coordinator.lockArchive();

    expect(await custody.hasLocalKeys(), isFalse);
  });

  test('lockArchive throws when keys remain after purge attempts', () async {
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
    store[KeyStorageKeys.evmPrivateKey] = '0xevm';
    store[KeyStorageKeys.vaultAesKey] = 'vault';

    expect(() => coordinator.lockArchive(), throwsA(isA<StateError>()));
  });
}
