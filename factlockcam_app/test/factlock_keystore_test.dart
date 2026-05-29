import 'dart:convert';
import 'dart:typed_data';

import 'package:factlockcam/core/ghost_key/factlock_keystore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FactlockKeystore', () {
    const password = 'strong-backup-password';
    const wrongPassword = 'wrong-password';

    test('round-trips composite payload through envelope', () async {
      final keystore = FactlockKeystore();
      final inner = FactlockKeystore.buildInnerPayload(
        evmPrivateKeyHex:
            '0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        vaultAesKeyEncoded: base64Encode(Uint8List.fromList(List.filled(32, 7))),
      );

      final envelope = await keystore.encryptInnerPayload(
        innerPayload: inner,
        password: password,
      );

      final restored = await keystore.decryptEnvelope(
        envelope: envelope,
        password: password,
      );

      expect(restored['evm_key'], inner['evm_key']);
      expect(restored['vault_key'], inner['vault_key']);
    });

    test('rejects wrong backup password via MAC mismatch', () async {
      final keystore = FactlockKeystore();
      final inner = FactlockKeystore.buildInnerPayload(
        evmPrivateKeyHex:
            '0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        vaultAesKeyEncoded: base64Encode(Uint8List.fromList(List.filled(32, 3))),
      );
      final envelope = await keystore.encryptInnerPayload(
        innerPayload: inner,
        password: password,
      );

      expect(
        () => keystore.decryptEnvelope(envelope: envelope, password: wrongPassword),
        throwsA(isA<StateError>()),
      );
    });

    test('parseEnvelopeJson rejects unsupported version', () {
      expect(
        () => FactlockKeystore.parseEnvelopeJson('{"version":99}'),
        throwsA(isA<FormatException>()),
      );
    });

    test('validateInnerPayload rejects invalid evm key', () {
      expect(
        () => FactlockKeystore.validateInnerPayload({
          'version': 1,
          'evm_key': 'not-a-key',
          'vault_key': base64Encode(Uint8List.fromList(List.filled(32, 1))),
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
