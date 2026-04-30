import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';

const _magicLinkRedirectUrl = 'snapseal://login-callback';

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (!AppConfig.hasSupabaseConfig) {
    return null;
  }
  return Supabase.instance.client;
});

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(supabaseClientProvider)),
);

class AuthRepository {
  const AuthRepository(this._client);

  final SupabaseClient? _client;

  bool get isConfigured => _client != null;

  Session? get currentSession => _client?.auth.currentSession;

  Future<void> sendMagicLink(String email) async {
    final client = _requiredClient();
    await client.auth.signInWithOtp(
      email: email.trim(),
      shouldCreateUser: true,
      emailRedirectTo: _magicLinkRedirectUrl,
    );
  }

  Future<void> signOut() async {
    await _client?.auth.signOut();
  }

  SupabaseClient _requiredClient() {
    final client = _client;
    if (client == null) {
      throw StateError(
        'Supabase is not configured. Run with --dart-define SUPABASE_URL=... '
        'and --dart-define SUPABASE_PUBLISHABLE_KEY=...',
      );
    }
    return client;
  }
}
