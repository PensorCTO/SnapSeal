import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

/// Initializes Supabase. On **web debug** builds, [AppConfig.effectiveSupabaseUrl]
/// resolves to local Kong at `http://127.0.0.1:54325` (see `supabase/config.toml` `[api].port`).
Future<void> initializeBackend() async {
  if (AppConfig.isFlutterTest) {
    return;
  }
  if (!AppConfig.hasSupabaseConfig) {
    return;
  }

  await Supabase.initialize(
    url: AppConfig.effectiveSupabaseUrl,
    anonKey: AppConfig.effectiveSupabaseAnonKey,
    debug: kDebugMode,
  );
}
