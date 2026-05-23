import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';

/// Registered in GetIt as a singleton; [client] resolves from [Supabase.instance]
/// on **each read** so repositories never keep a stale `null` snapshot from a
/// moment before [Supabase.initialize] completed (or from an early catch of
/// [StateError]).
class SupabaseClientHandle {
  SupabaseClient? get client {
    if (!AppConfig.hasSupabaseConfig) {
      return null;
    }
    try {
      return Supabase.instance.client;
    } on StateError {
      return null;
    } on AssertionError {
      return null;
    }
  }
}
