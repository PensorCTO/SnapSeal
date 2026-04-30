class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const _supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get supabaseAnonKey => _supabasePublishableKey.isNotEmpty
      ? _supabasePublishableKey
      : _supabaseAnonKey;

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
