import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/crypto/courier_crypto.dart';
import '../../core/crypto/vault_encryption_handler.dart';
import '../../core/di/locator.dart';
import '../../data/supabase/courier_repository.dart';

final courierUnlockProvider =
    NotifierProvider<CourierUnlockNotifier, CourierUnlockState>(
  CourierUnlockNotifier.new,
);

class CourierUnlockState {
  const CourierUnlockState({
    this.attemptStatus,
    this.verifiedBytes,
    this.fileExtension,
    this.message,
    this.isLoading = false,
  });

  final Map<String, dynamic>? attemptStatus;
  final Uint8List? verifiedBytes;
  final String? fileExtension;
  final String? message;
  final bool isLoading;

  bool get isLocked => attemptStatus?['locked'] == true;

  CourierUnlockState copyWith({
    Map<String, dynamic>? attemptStatus,
    Uint8List? verifiedBytes,
    String? fileExtension,
    String? message,
    bool? isLoading,
    bool clearVerified = false,
    bool clearMessage = false,
  }) =>
      CourierUnlockState(
        attemptStatus: attemptStatus ?? this.attemptStatus,
        verifiedBytes:
            clearVerified ? null : (verifiedBytes ?? this.verifiedBytes),
        fileExtension:
            clearVerified ? null : (fileExtension ?? this.fileExtension),
        message: clearMessage ? null : (message ?? this.message),
        isLoading: isLoading ?? this.isLoading,
      );
}

class CourierUnlockNotifier extends Notifier<CourierUnlockState> {
  final _vault = DefaultVaultEncryptionHandler();
  late final CourierRepository _courierRepository;

  @override
  CourierUnlockState build() {
    _courierRepository = getIt<CourierRepository>();
    return const CourierUnlockState();
  }

  bool get _canUseBackend => AppConfig.hasSupabaseConfig;

  Future<void> loadAttemptStatus(String? packageId) async {
    if (!_canUseBackend) {
      state = state.copyWith(
        attemptStatus: null,
        message: 'Supabase is not configured for this build.',
        isLoading: false,
      );
      return;
    }

    if (packageId == null || packageId.isEmpty) {
      state = state.copyWith(
        attemptStatus: null,
        message: 'Missing courier package id.',
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearMessage: true);

    try {
      final attemptStatus = await _courierRepository.checkCourierAttempts(
        packageId,
      );
      state = state.copyWith(
        attemptStatus: attemptStatus,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(message: error.toString(), isLoading: false);
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

    state = state.copyWith(
      isLoading: true,
      clearMessage: true,
      clearVerified: true,
    );

    try {
      final row = await _courierRepository.attemptUnlock(
        packageId: packageId,
        verifierGuess: challenge,
        requestorEmail: email,
      );
      final signedUrl = row['signed_url'] as String?;
      if (signedUrl == null || signedUrl.isEmpty) {
        throw StateError('Courier unlock did not return a signed download URL.');
      }
      final encryptedBytes = await _courierRepository.downloadSignedBlob(
        signedUrl,
      );
      final verifiedBytes = await CourierCrypto.decryptAndVerifyFingerprint(
        vault: _vault,
        encryptedPayload: encryptedBytes,
        keyBytes: _vault.decodeKey(row['key'] as String),
        expectedFingerprint: row['asset_hash'] as String,
      );

      state = state.copyWith(
        verifiedBytes: verifiedBytes,
        fileExtension: (row['file_extension'] as String).toLowerCase(),
        message: 'Verified SHA-256 fingerprint and decrypted in browser RAM.',
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(message: error.toString(), isLoading: false);
      await loadAttemptStatus(packageId);
    }
  }

  void reset() {
    state = const CourierUnlockState();
  }
}
