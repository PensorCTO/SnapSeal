import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/crypto/courier_crypto.dart';
import '../../core/crypto/vault_encryption_handler.dart';
import '../../core/di/service_providers.dart';
import '../../data/supabase/courier_repository.dart';
import 'courier_unlock_phase.dart';

const cascadeAnimationDuration = Duration(milliseconds: 1500);

final courierUnlockProvider =
    NotifierProvider<CourierUnlockNotifier, CourierUnlockState>(
  CourierUnlockNotifier.new,
);

class CourierUnlockState {
  const CourierUnlockState({
    this.phase = CourierUnlockPhase.idle,
    this.attemptStatus,
    this.verifiedBytes,
    this.fileExtension,
    this.contentMimeType,
    this.targetAssetHash,
    this.attestation,
    this.message,
    this.showProofDeepDive = false,
    this.playbackCompleted = false,
  });

  final CourierUnlockPhase phase;
  final Map<String, dynamic>? attemptStatus;
  final Uint8List? verifiedBytes;
  final String? fileExtension;
  final String? contentMimeType;
  final String? targetAssetHash;
  final Map<String, dynamic>? attestation;
  final String? message;
  final bool showProofDeepDive;
  final bool playbackCompleted;

  bool get isLoading => phase == CourierUnlockPhase.processing;

  bool get isLocked => attemptStatus?['locked'] == true;

  CourierUnlockState copyWith({
    CourierUnlockPhase? phase,
    Map<String, dynamic>? attemptStatus,
    Uint8List? verifiedBytes,
    String? fileExtension,
    String? contentMimeType,
    String? targetAssetHash,
    Map<String, dynamic>? attestation,
    String? message,
    bool? showProofDeepDive,
    bool? playbackCompleted,
    bool clearVerified = false,
    bool clearMessage = false,
    bool clearAttestation = false,
    bool clearTargetHash = false,
  }) =>
      CourierUnlockState(
        phase: phase ?? this.phase,
        attemptStatus: attemptStatus ?? this.attemptStatus,
        verifiedBytes:
            clearVerified ? null : (verifiedBytes ?? this.verifiedBytes),
        fileExtension:
            clearVerified ? null : (fileExtension ?? this.fileExtension),
        contentMimeType:
            clearVerified ? null : (contentMimeType ?? this.contentMimeType),
        targetAssetHash:
            clearTargetHash ? null : (targetAssetHash ?? this.targetAssetHash),
        attestation: clearAttestation ? null : (attestation ?? this.attestation),
        message: clearMessage ? null : (message ?? this.message),
        showProofDeepDive: showProofDeepDive ?? this.showProofDeepDive,
        playbackCompleted: playbackCompleted ?? this.playbackCompleted,
      );
}

class _PendingUnlockPayload {
  const _PendingUnlockPayload({
    required this.key,
    required this.fileExtension,
    required this.assetHash,
    required this.encryptedBytes,
    this.contentMimeType,
  });

  final String key;
  final String fileExtension;
  final String assetHash;
  final Uint8List encryptedBytes;
  final String? contentMimeType;
}

class CourierUnlockNotifier extends Notifier<CourierUnlockState> {
  final _vault = DefaultArchiveEncryptionHandler();
  late final CourierRepository _courierRepository;
  _PendingUnlockPayload? _pending;
  int _unlockGeneration = 0;

  @override
  CourierUnlockState build() {
    _courierRepository = ref.read(courierRepositoryProvider);
    return const CourierUnlockState();
  }

  bool get _canUseBackend => AppConfig.hasSupabaseConfig;

  Future<void> loadAttemptStatus(String? packageId) async {
    if (!_canUseBackend) {
      state = state.copyWith(
        phase: CourierUnlockPhase.idle,
        attemptStatus: null,
        message: 'Supabase is not configured for this build.',
      );
      return;
    }

    if (packageId == null || packageId.isEmpty) {
      state = state.copyWith(
        phase: CourierUnlockPhase.idle,
        attemptStatus: null,
        message: 'Missing courier package id.',
      );
      return;
    }

    state = state.copyWith(
      phase: CourierUnlockPhase.processing,
      clearMessage: true,
    );

    try {
      final attemptStatus = await _courierRepository.checkCourierAttempts(
        packageId,
      );
      state = state.copyWith(
        phase: CourierUnlockPhase.idle,
        attemptStatus: attemptStatus,
      );
    } catch (error) {
      state = state.copyWith(
        phase: CourierUnlockPhase.idle,
        message: error.toString(),
      );
    }
  }

  Future<void> unlock(
    String? packageId,
    String challenge,
    String email,
  ) async {
    if (!_canUseBackend || packageId == null || packageId.isEmpty) {
      return;
    }

    final generation = ++_unlockGeneration;
    _pending = null;

    state = state.copyWith(
      phase: CourierUnlockPhase.processing,
      clearMessage: true,
      clearVerified: true,
      clearAttestation: true,
      clearTargetHash: true,
      playbackCompleted: false,
      showProofDeepDive: false,
    );

    try {
      await _authenticate(
        packageId: packageId,
        challenge: challenge,
        email: email,
        generation: generation,
      );
    } catch (error) {
      if (generation != _unlockGeneration) return;
      state = state.copyWith(
        phase: CourierUnlockPhase.idle,
        message: error.toString(),
      );
      await loadAttemptStatus(packageId);
    }
  }

  Future<void> _authenticate({
    required String packageId,
    required String challenge,
    required String email,
    required int generation,
  }) async {
    final row = await _courierRepository.attemptUnlock(
      packageId: packageId,
      verifierGuess: challenge,
      requestorEmail: email,
    );

    if (generation != _unlockGeneration) return;

    final signedUrl = row['signed_url'] as String?;
    if (signedUrl == null || signedUrl.isEmpty) {
      throw StateError('Courier unlock did not return a signed download URL.');
    }

    final assetHash = row['asset_hash'] as String;
    final encryptedBytes = await _courierRepository.downloadSignedBlob(
      signedUrl,
    );

    if (generation != _unlockGeneration) return;

    _pending = _PendingUnlockPayload(
      key: row['key'] as String,
      fileExtension: (row['file_extension'] as String).toLowerCase(),
      assetHash: assetHash,
      encryptedBytes: encryptedBytes,
      contentMimeType: row['content_mime_type'] as String?,
    );

    state = state.copyWith(
      phase: CourierUnlockPhase.cascadeAnimation,
      targetAssetHash: assetHash,
    );

    unawaited(_fetchAttestation(assetHash, generation));

    await _runCascadeThenVerify(generation);
  }

  Future<void> _runCascadeThenVerify(int generation) async {
    await Future<void>.delayed(cascadeAnimationDuration);

    if (generation != _unlockGeneration) return;

    final pending = _pending;
    if (pending == null) {
      state = state.copyWith(
        phase: CourierUnlockPhase.idle,
        message: 'Unlock session expired. Try again.',
      );
      return;
    }

    try {
      final verifiedBytes = await CourierCrypto.decryptAndVerifyFingerprint(
        vault: _vault,
        encryptedPayload: pending.encryptedBytes,
        keyBytes: _vault.decodeKey(pending.key),
        expectedFingerprint: pending.assetHash,
      );

      if (generation != _unlockGeneration) return;

      _pending = null;
      state = state.copyWith(
        phase: CourierUnlockPhase.playbackReady,
        verifiedBytes: verifiedBytes,
        fileExtension: pending.fileExtension,
        contentMimeType: pending.contentMimeType,
        targetAssetHash: pending.assetHash,
        message: 'Verified SHA-256 fingerprint and decrypted in browser RAM.',
      );
    } catch (error) {
      if (generation != _unlockGeneration) return;
      _pending = null;
      state = state.copyWith(
        phase: CourierUnlockPhase.idle,
        message: error.toString(),
      );
    }
  }

  Future<void> _fetchAttestation(String assetHash, int generation) async {
    try {
      final attestation = await _courierRepository.fetchPublicAttestation(
        assetHash,
      );
      if (generation != _unlockGeneration) return;
      state = state.copyWith(attestation: attestation);
    } catch (_) {
      // Proof panel degrades to hash-only when attestation fetch fails.
    }
  }

  void toggleProofDeepDive() {
    state = state.copyWith(showProofDeepDive: !state.showProofDeepDive);
  }

  void onPlaybackCompleted() {
    if (state.phase != CourierUnlockPhase.playbackReady) return;
    state = state.copyWith(
      phase: CourierUnlockPhase.viralLoop,
      playbackCompleted: true,
    );
  }

  void dismissViralLoop() {
    if (state.phase != CourierUnlockPhase.viralLoop) return;
    state = state.copyWith(phase: CourierUnlockPhase.playbackReady);
  }

  Future<Map<String, dynamic>> reportPackage({
    required String packageId,
    required String reason,
    String? detail,
    String? reporterEmail,
  }) {
    return _courierRepository.reportCourierPackage(
      packageId: packageId,
      reason: reason,
      detail: detail,
      reporterEmail: reporterEmail,
    );
  }

  Future<Map<String, dynamic>> blockSender({
    required String packageId,
    String? reporterEmail,
  }) {
    return _courierRepository.blockCourierSender(
      packageId: packageId,
      reporterEmail: reporterEmail,
    );
  }

  void reset() {
    _unlockGeneration++;
    _pending = null;
    state = const CourierUnlockState();
  }
}
