import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:factlockcam/core/crypto/archive_encryption_handler.dart';
import 'package:factlockcam/core/di/service_providers.dart';
import 'package:factlockcam/data/supabase/courier_repository.dart';
import 'package:factlockcam/data/supabase/supabase_client_handle.dart';
import 'package:factlockcam/ui/web/courier_unlock_notifier.dart';
import 'package:factlockcam/ui/web/courier_unlock_phase.dart';

import 'test_dependencies.dart';

class _FakeCourierRepository extends CourierRepository {
  _FakeCourierRepository(this._handlers) : super(SupabaseClientHandle());

  final _FakeCourierHandlers _handlers;

  @override
  Future<Map<String, dynamic>> checkCourierAttempts(String packageId) async {
    return _handlers.checkAttempts(packageId);
  }

  @override
  Future<Map<String, dynamic>> attemptUnlock({
    required String packageId,
    required String verifierGuess,
    required String requestorEmail,
  }) async {
    return _handlers.attemptUnlock(
      packageId: packageId,
      verifierGuess: verifierGuess,
      requestorEmail: requestorEmail,
    );
  }

  @override
  Future<Uint8List> downloadSignedBlob(String signedUrl) async {
    return _handlers.downloadSignedBlob(signedUrl);
  }

  @override
  Future<Map<String, dynamic>> fetchPublicAttestation(String assetHash) async {
    return _handlers.fetchPublicAttestation(assetHash);
  }
}

class _FakeCourierHandlers {
  _FakeCourierHandlers({
    required this.unlockRow,
    required this.encryptedBytes,
  });

  final Map<String, dynamic> unlockRow;
  final Uint8List encryptedBytes;

  Future<Map<String, dynamic>> checkAttempts(String packageId) async {
    return {
      'status': 'available',
      'locked': false,
      'attempts_remaining': 5,
    };
  }

  Future<Map<String, dynamic>> attemptUnlock({
    required String packageId,
    required String verifierGuess,
    required String requestorEmail,
  }) async {
    return unlockRow;
  }

  Future<Uint8List> downloadSignedBlob(String signedUrl) async {
    return encryptedBytes;
  }

  Future<Map<String, dynamic>> fetchPublicAttestation(String assetHash) async {
    return {
      'found': true,
      'chain_tx_hash': '0xabc',
      'sealed_at': '2026-06-05T12:00:00Z',
      'block_number': null,
    };
  }
}

void main() {
  setUpAll(() async {
    await setupTestDependencies();
  });

  test('unlock enters cascade without verifiedBytes before delay elapses', () async {
    final vault = DefaultArchiveEncryptionHandler();
    final plaintext = Uint8List.fromList(utf8.encode('courier-test-payload'));
    final keyBytes = Uint8List.fromList(List<int>.filled(32, 9));
    final encodedKey = base64Encode(keyBytes);
    final encrypted = await vault.encrypt(bytes: plaintext, keyBytes: keyBytes);
    final assetHash = await vault.generateHash(plaintext);

    final fake = _FakeCourierRepository(
      _FakeCourierHandlers(
        unlockRow: {
          'signed_url': 'https://example.test/blob',
          'key': encodedKey,
          'file_extension': '.jpg',
          'asset_hash': assetHash,
          'content_mime_type': 'image/jpeg',
        },
        encryptedBytes: encrypted,
      ),
    );

    final container = ProviderContainer(
      overrides: [
        courierRepositoryProvider.overrideWithValue(fake),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(courierUnlockProvider.notifier);
    final unlockFuture = notifier.unlock('pkg-id', 'secret', 'a@test.com');

    await Future<void>.delayed(Duration.zero);
    final mid = container.read(courierUnlockProvider);
    expect(mid.phase, CourierUnlockPhase.cascadeAnimation);
    expect(mid.verifiedBytes, isNull);
    expect(mid.targetAssetHash, assetHash);

    await unlockFuture;
    final done = container.read(courierUnlockProvider);
    expect(done.phase, CourierUnlockPhase.playbackReady);
    expect(done.verifiedBytes, plaintext);
    expect(done.attestation?['chain_tx_hash'], '0xabc');
  });

  test('onPlaybackCompleted transitions to viralLoop from playbackReady', () {
    final container = ProviderContainer(
      overrides: [
        courierUnlockProvider.overrideWith(_PlaybackReadyNotifier.new),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(courierUnlockProvider.notifier);

    notifier.onPlaybackCompleted();
    expect(
      container.read(courierUnlockProvider).phase,
      CourierUnlockPhase.viralLoop,
    );

    notifier.dismissViralLoop();
    expect(
      container.read(courierUnlockProvider).phase,
      CourierUnlockPhase.playbackReady,
    );

    notifier.toggleProofDeepDive();
    expect(container.read(courierUnlockProvider).showProofDeepDive, isTrue);
  });
}

class _PlaybackReadyNotifier extends CourierUnlockNotifier {
  @override
  CourierUnlockState build() {
    return const CourierUnlockState(phase: CourierUnlockPhase.playbackReady);
  }
}
