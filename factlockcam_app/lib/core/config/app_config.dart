class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const _usePolygonNotarizer = bool.fromEnvironment(
    'USE_POLYGON_NOTARIZER',
    defaultValue: false,
  );
  static const _requireHardwareAttestation = bool.fromEnvironment(
    'REQUIRE_HARDWARE_ATTESTATION',
    defaultValue: false,
  );

  static String get supabaseAnonKey => _supabaseAnonKey;

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get usePolygonNotarizer => _usePolygonNotarizer;
  static bool get requireHardwareAttestation => _requireHardwareAttestation;
}
