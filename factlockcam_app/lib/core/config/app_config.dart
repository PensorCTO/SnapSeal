import 'package:flutter/foundation.dart';

import 'generated_dart_defines.dart';

class AppConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: GeneratedDartDefines.supabaseUrl,
  );
  static const _supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: GeneratedDartDefines.supabaseAnonKey,
  );
  /// Local Supabase REST/Kong URL; port must match `supabase/config.toml` `[api].port`.
  static const localSupabaseUrl = 'http://127.0.0.1:54325';
  static const _localAnonKey = String.fromEnvironment(
    'LOCAL_ANON_KEY',
    defaultValue: GeneratedDartDefines.localAnonKey,
  );
  static const _usePolygonNotarizer = bool.fromEnvironment(
    'USE_POLYGON_NOTARIZER',
    defaultValue: GeneratedDartDefines.usePolygonNotarizer,
  );
  static const _requireHardwareAttestation = bool.fromEnvironment(
    'REQUIRE_HARDWARE_ATTESTATION',
    defaultValue: false,
  );
  static const _webVaultBaseUrl = String.fromEnvironment(
    'WEB_VAULT_BASE_URL',
    defaultValue: GeneratedDartDefines.webVaultBaseUrl,
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

  static String get webVaultBaseUrl => _webVaultBaseUrl;

  /// Placeholder support/marketing URL for App Store submission requirements.
  static const supportWebsiteUrl = 'https://factlockcam.com/support';

  /// Deprecated external legal URLs — native bundled documents are preferred.
  @Deprecated('Use offline LegalDocumentView assets instead.')
  static const legalEulaUrl = 'https://factlockcam.com/eula';

  @Deprecated('Use offline LegalDocumentView assets instead.')
  static const legalPrivacyUrl = 'https://factlockcam.com/privacy';
}
