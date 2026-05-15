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

  static String get effectiveSupabaseUrl =>
      isLocalWeb ? localSupabaseUrl : supabaseUrl;

  static String get effectiveSupabaseAnonKey =>
      isLocalWeb ? localAnonKey : supabaseAnonKey;

  static bool get hasSupabaseConfig =>
      effectiveSupabaseUrl.isNotEmpty && effectiveSupabaseAnonKey.isNotEmpty;

  static bool get usePolygonNotarizer => _usePolygonNotarizer;
  static bool get requireHardwareAttestation => _requireHardwareAttestation;
}
