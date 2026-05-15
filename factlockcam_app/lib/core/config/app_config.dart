import 'package:flutter/foundation.dart';

class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  /// Local Supabase REST/Kong URL; port must match `supabase/config.toml` `[api].port`.
  static const localSupabaseUrl = 'http://127.0.0.1:54325';
  static const _localAnonKey = String.fromEnvironment('LOCAL_ANON_KEY');
  static const _usePolygonNotarizer = bool.fromEnvironment(
    'USE_POLYGON_NOTARIZER',
    defaultValue: false,
  );
  static const _requireHardwareAttestation = bool.fromEnvironment(
    'REQUIRE_HARDWARE_ATTESTATION',
    defaultValue: false,
  );

  static String get supabaseAnonKey => _supabaseAnonKey;
  static String get localAnonKey => _localAnonKey;

  static bool get isLocalWeb => kIsWeb && kDebugMode;

  /// Strips duplicated scheme from bad env copy-paste, e.g. `https://https://…`.
  static String normalizeSupabaseProjectUrl(String url) {
    var u = url.trim();
    while (u.startsWith('https://https://')) {
      u = u.substring('https://'.length);
    }
    if (u.startsWith('http://https://')) {
      u = 'https://${u.substring('http://https://'.length)}';
    }
    return u;
  }

  static String get effectiveSupabaseUrl {
    final raw = isLocalWeb ? localSupabaseUrl : supabaseUrl;
    if (raw.isEmpty) return raw;
    return normalizeSupabaseProjectUrl(raw);
  }

  static String get effectiveSupabaseAnonKey =>
      isLocalWeb ? localAnonKey : supabaseAnonKey;

  static bool get hasSupabaseConfig =>
      effectiveSupabaseUrl.isNotEmpty && effectiveSupabaseAnonKey.isNotEmpty;

  static bool get usePolygonNotarizer => _usePolygonNotarizer;
  static bool get requireHardwareAttestation => _requireHardwareAttestation;
}
