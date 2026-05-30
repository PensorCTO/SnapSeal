// Empty fallback template — run scripts/sync_flutter_dart_defines.sh to populate
// generated_dart_defines.dart from repo-root `.env.local`.

/// Fallback Supabase / app defines when CLI omits `--dart-define`.
abstract final class GeneratedDartDefines {
  static const supabaseUrl = '';
  static const supabaseAnonKey = '';
  static const localAnonKey = '';
  static const webBaseUrl = 'https://factlockcam.com';
  static const webArchiveBaseUrl = 'https://archive.factlockcam.com';
  static const appEnvironment = 'production';
  static const supportUrl = '';
  static const usePolygonNotarizer = false;
  static const polygonRpcUrl = '';
  static const enableProofLinks = false;
}
