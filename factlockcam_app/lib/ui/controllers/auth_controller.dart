import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/supabase/auth_repository.dart';
import '../../domain/services/vault_service.dart';

final authStateProvider = StreamProvider<AuthState?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    return Stream.value(null);
  }
  return client.auth.onAuthStateChange;
});

final authControllerProvider = NotifierProvider<AuthController, AuthUiState>(
  AuthController.new,
);

class AuthUiState {
  const AuthUiState({
    required this.isConfigured,
    this.isLoading = false,
    this.otpSent = false,
    this.isAuthenticated = false,
    this.error,
  });

  final bool isConfigured;
  final bool isLoading;
  final bool otpSent;
  final bool isAuthenticated;
  final String? error;

  AuthUiState copyWith({
    bool? isLoading,
    bool? otpSent,
    bool? isAuthenticated,
    String? error,
    bool clearError = false,
  }) => AuthUiState(
    isConfigured: isConfigured,
    isLoading: isLoading ?? this.isLoading,
    otpSent: otpSent ?? this.otpSent,
    isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    error: clearError ? null : error ?? this.error,
  );
}

class AuthController extends Notifier<AuthUiState> {
  @override
  AuthUiState build() {
    final repository = ref.watch(authRepositoryProvider);
    ref.listen(authStateProvider, (previous, next) {
      final authChange = next.asData?.value;
      final hasSession = authChange?.session != null;
      state = state.copyWith(
        isAuthenticated: hasSession,
        otpSent: hasSession ? false : state.otpSent,
      );
    });

    return AuthUiState(
      isConfigured: repository.isConfigured,
      isAuthenticated: repository.currentSession != null,
    );
  }

  Future<bool> sendOtp(String email) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        otpSent: false,
        error: 'Enter your email address.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true, otpSent: false);

    try {
      final client = ref.read(supabaseClientProvider);
      if (client == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Supabase is not configured.',
        );
        return false;
      }
      await client.auth.signInWithOtp(
        email: normalizedEmail,
        shouldCreateUser: true,
      );
      state = state.copyWith(isLoading: false, otpSent: true);
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
      return false;
    }
  }

  Future<bool> verifyOtp({required String email, required String token}) async {
    final normalizedEmail = email.trim();
    final normalizedToken = token.trim();
    if (normalizedEmail.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        error: 'Enter your email address.',
      );
      return false;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(normalizedToken)) {
      state = state.copyWith(
        isLoading: false,
        error: 'Enter the 6-digit code from your email.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final client = ref.read(supabaseClientProvider);
      if (client == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Supabase is not configured.',
        );
        return false;
      }

      await client.auth.verifyOTP(
        email: normalizedEmail,
        token: normalizedToken,
        type: OtpType.email,
      );
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        otpSent: false,
      );
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
      return false;
    }
  }

  /// Ends the Supabase session only. Local archive data remains on this device.
  /// Use [performFullBurn] to wipe local vault files and delete the remote account.
  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = state.copyWith(isAuthenticated: false, otpSent: false);
  }

  /// Remote account deletion then local wallet burn. Session may already be invalid.
  Future<void> performFullBurn() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref.read(authRepositoryProvider).performFullBurn();
    } finally {
      await ref.read(vaultServiceProvider).burnLocalWallet();
      try {
        await ref.read(authRepositoryProvider).signOut();
      } catch (_) {
        // User row may already be gone after perform_full_burn.
      }
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        otpSent: false,
      );
    }
  }
}
