import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web3dart/web3dart.dart';

import '../../core/di/locator.dart';
import '../../core/ghost_key/native_enclave_channel.dart';
import '../../data/supabase/seal_ledger_repository.dart';

/// EVM-compatible signing abstraction for ProofLock notarization.
///
/// **Inputs:** SHA-256 content hash (`String`, hex-encoded).
/// **Outputs:** Hex-encoded EIP-191 signature (`String`, `0x` prefixed).
/// **Expected failure modes:** Missing wallet keys, secure storage errors,
/// Supabase profile sync failures.
abstract class WalletService {
  Future<String> signMessageHash(String hash);

  /// Ensures an EVM address exists and is mirrored to `profiles.evm_address`.
  Future<String> ensureEvmAddress();
}

/// Hardware-backed signing via platform MethodChannel (simulated chain path).
class SimulatedWalletService implements WalletService {
  SimulatedWalletService(this._nativeEnclave);

  final NativeEnclaveChannel _nativeEnclave;

  @override
  Future<String> signMessageHash(String hash) => _nativeEnclave.signHash(hash);

  @override
  Future<String> ensureEvmAddress() async => '';
}

/// Production EVM wallet signer backed by [FlutterSecureStorage].
class PolygonWalletService implements WalletService {
  PolygonWalletService({
    required FlutterSecureStorage secureStorage,
    required SealLedgerRepository sealLedgerRepository,
  })  : _secureStorage = secureStorage,
        _sealLedgerRepository = sealLedgerRepository;

  static const _privateKeyStorageKey = 'factlockcam:evm_private_key';

  final FlutterSecureStorage _secureStorage;
  final SealLedgerRepository _sealLedgerRepository;

  @override
  Future<String> ensureEvmAddress() async {
    final credentials = await _loadOrCreateCredentials();
    final address = credentials.address.hexEip55;
    if (_sealLedgerRepository.isConfigured) {
      await _sealLedgerRepository.syncEvmAddress(address);
    }
    return address;
  }

  @override
  Future<String> signMessageHash(String hash) async {
    await ensureEvmAddress();
    final privateKeyHex = await _secureStorage.read(key: _privateKeyStorageKey);
    if (privateKeyHex == null || privateKeyHex.isEmpty) {
      throw StateError('EVM private key missing after ensureEvmAddress.');
    }
    return Isolate.run(
      () => _signHashInIsolate(hash: hash, privateKeyHex: privateKeyHex),
    );
  }

  Future<EthPrivateKey> _loadOrCreateCredentials() async {
    var stored = await _secureStorage.read(key: _privateKeyStorageKey);
    if (stored == null || stored.isEmpty) {
      final generated = EthPrivateKey.createRandom(Random.secure());
      stored = '0x${_bytesToHex(generated.privateKey)}';
      await _secureStorage.write(key: _privateKeyStorageKey, value: stored);
    }
    return EthPrivateKey.fromHex(stored);
  }
}

String _signHashInIsolate({
  required String hash,
  required String privateKeyHex,
}) {
  final credentials = EthPrivateKey.fromHex(privateKeyHex);
  final hashBytes = _decodeHashBytes(hash);
  final signature = credentials.signPersonalMessageToUint8List(hashBytes);
  return '0x${_bytesToHex(signature)}';
}

String _bytesToHex(List<int> bytes) {
  final buffer = StringBuffer();
  for (final byte in bytes) {
    buffer.write(byte.toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}

Uint8List _decodeHashBytes(String hash) {
  return _hashByteCache.putIfAbsent(hash.trim().toLowerCase(), () {
    var normalized = hash.trim().toLowerCase();
    if (normalized.startsWith('0x')) {
      normalized = normalized.substring(2);
    }
    if (normalized.length != 64) {
      throw ArgumentError.value(hash, 'hash', 'Expected 32-byte SHA-256 hex.');
    }
    return Uint8List.fromList(
      List.generate(normalized.length ~/ 2, (index) {
        final byte = normalized.substring(index * 2, index * 2 + 2);
        return int.parse(byte, radix: 16);
      }),
    );
  });
}

final Map<String, Uint8List> _hashByteCache = <String, Uint8List>{};

final walletServiceProvider = Provider<WalletService>(
  (ref) => getIt<WalletService>(),
);
