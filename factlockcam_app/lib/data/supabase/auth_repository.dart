import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/di/locator.dart';

import 'supabase_client_handle.dart';

final supabaseClientProvider = Provider<SupabaseClient?>(
  (ref) => getIt<SupabaseClientHandle>().client,
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => getIt<AuthRepository>(),
);

class AuthRepository {
  AuthRepository(this._handle);

  final SupabaseClientHandle _handle;

  bool get isConfigured => _handle.client != null;

  Session? get currentSession => _handle.client?.auth.currentSession;
  String? get currentUserId => currentSession?.user.id;

  Future<void> signOut() async {
    await _handle.client?.auth.signOut();
  }

  /// Permanently deletes the authenticated user and remote wallet data (App Store).
  Future<void> performFullBurn() async {
    final client = _handle.client;
    if (client == null) {
      throw StateError('Supabase is not configured.');
    }
    if (client.auth.currentUser == null) {
      throw StateError('No authenticated user for account deletion.');
    }
    await client.rpc('perform_full_burn');
  }
}
