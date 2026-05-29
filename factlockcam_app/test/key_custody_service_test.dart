import 'package:factlockcam/core/ghost_key/key_custody_service.dart';
import 'package:factlockcam/core/ghost_key/key_storage_keys.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockSecureStorage storage;
  late KeyCustodyService service;
  final store = <String, String>{};

  setUp(() {
    storage = _MockSecureStorage();
    store.clear();
    service = KeyCustodyService(secureStorage: storage);

    when(() => storage.read(key: any(named: 'key'))).thenAnswer((invocation) async {
      final key = invocation.namedArguments[#key] as String;
      return store[key];
    });
    when(() => storage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((invocation) async {
      final key = invocation.namedArguments[#key] as String;
      final value = invocation.namedArguments[#value] as String;
      store[key] = value;
    });
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((invocation) async {
      final key = invocation.namedArguments[#key] as String;
      store.remove(key);
    });
  });

  test('hasLocalKeys is true only when both keys exist', () async {
    expect(await service.hasLocalKeys(), isFalse);

    store[KeyStorageKeys.evmPrivateKey] = '0xabc';
    expect(await service.hasLocalKeys(), isFalse);

    store[KeyStorageKeys.vaultAesKey] = 'vault';
    expect(await service.hasLocalKeys(), isTrue);
  });

  test('rehydrateKeys writes both sovereign keys', () async {
    await service.rehydrateKeys(
      evmPrivateKeyHex: '0xevm',
      vaultAesKeyEncoded: 'vault-encoded',
    );

    expect(store[KeyStorageKeys.evmPrivateKey], '0xevm');
    expect(store[KeyStorageKeys.vaultAesKey], 'vault-encoded');
  });

  test('purgeAllLocalKeys removes both keys', () async {
    store[KeyStorageKeys.evmPrivateKey] = '0xevm';
    store[KeyStorageKeys.vaultAesKey] = 'vault';
    store[KeyStorageKeys.legacyVaultAesKey] = 'legacy';

    await service.purgeAllLocalKeys();

    expect(await service.hasLocalKeys(), isFalse);
    expect(store.containsKey(KeyStorageKeys.legacyVaultAesKey), isFalse);
  });
}
