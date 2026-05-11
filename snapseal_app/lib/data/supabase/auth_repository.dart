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
}
