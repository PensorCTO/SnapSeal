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
        email: email.trim(),
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

      final normalizedToken = token.trim();
      if (normalizedToken.length != 6) {
        state = state.copyWith(
          isLoading: false,
          error: 'Enter the 6-digit code from your email.',
        );
        return false;
      }

      await client.auth.verifyOTP(
        email: email.trim(),
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

  Future<void> signOut() async {
    await ref.read(vaultServiceProvider).burnLocalWallet();
    await ref.read(authRepositoryProvider).signOut();
    state = state.copyWith(isAuthenticated: false, otpSent: false);
  }
}
