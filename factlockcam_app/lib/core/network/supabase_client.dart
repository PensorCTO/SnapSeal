import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

/// Maximum time to block [main] on Supabase SDK setup (session restore, prefs).
///
/// QA devices on poor networks must still reach the first frame; auth retries
/// after launch via [AuthController].
const _initializeTimeout = Duration(seconds: 12);

/// Initializes Supabase. On **web debug** builds, [AppConfig.effectiveSupabaseUrl]
/// resolves to local Kong at `http://127.0.0.1:54325` (see `supabase/config.toml` `[api].port`).
Future<void> initializeBackend() async {
  if (AppConfig.isFlutterTest) {
    return;
  }
  if (!AppConfig.hasSupabaseConfig) {
    return;
  }

  try {
    await Supabase.initialize(
      url: AppConfig.effectiveSupabaseUrl,
      anonKey: AppConfig.effectiveSupabaseAnonKey,
      debug: kDebugMode,
    ).timeout(_initializeTimeout);
  } on TimeoutException {
    debugPrint(
      'Supabase.initialize timed out after ${_initializeTimeout.inSeconds}s; '
      'continuing launch (offline-first).',
    );
  } catch (error, stackTrace) {
    debugPrint('Supabase.initialize failed: $error\n$stackTrace');
  }
}
