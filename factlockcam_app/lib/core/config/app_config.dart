import 'package:flutter/foundation.dart';

import 'generated_dart_defines.dart';
import 'runtime_test_flag.dart';

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
  static const _webArchiveBaseUrl = String.fromEnvironment(
    'WEB_ARCHIVE_BASE_URL',
    defaultValue: GeneratedDartDefines.webArchiveBaseUrl,
  );
  static const _appEnvironment = String.fromEnvironment(
    'APP_ENVIRONMENT',
    defaultValue: GeneratedDartDefines.appEnvironment,
  );
  static const _webBaseUrl = String.fromEnvironment(
    'WEB_BASE_URL',
    defaultValue: GeneratedDartDefines.webBaseUrl,
  );
  static const _supportUrl = String.fromEnvironment(
    'SUPPORT_URL',
    defaultValue: GeneratedDartDefines.supportUrl,
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

  /// Polygon JSON-RPC endpoint for on-chain transaction receipt monitoring.
  ///
  /// Set via `--dart-define=POLYGON_RPC_URL=...` at build time.
  /// Returns null if unset, allowing the monitor service to degrade gracefully.
  static String? get polygonRpcUrl {
    const fromEnv = String.fromEnvironment('POLYGON_RPC_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    const fromGenerated = GeneratedDartDefines.polygonRpcUrl;
    if (fromGenerated.isNotEmpty) return fromGenerated;
    return null;
  }

  static String get webArchiveBaseUrl => _webArchiveBaseUrl;

  /// Deprecated alias — prefer [webArchiveBaseUrl].
  @Deprecated('Use webArchiveBaseUrl')
  static String get webVaultBaseUrl => _webArchiveBaseUrl;

  /// Compile-time deployment target (`development`, `staging`, `production`, …).
  static String get appEnvironment =>
      _appEnvironment.isNotEmpty ? _appEnvironment : 'development';

  static bool get isProduction => appEnvironment == 'production';

  /// True while running under `flutter test` (Supabase/network quarantine).
  static bool get isFlutterTest => isRunningFlutterTest;

  /// Cloudflare Pages origin for marketing and compliance (Astro SSG).
  ///
  /// Override with `--dart-define=WEB_BASE_URL=...` at build time.
  static String get webBaseUrl => _webBaseUrl.isNotEmpty
      ? _webBaseUrl
      : 'https://factlockcam.pages.dev';

  /// Permanent support URL for App Store Connect and in-app settings.
  ///
  /// Uses [SUPPORT_URL] when set; otherwise `{webBaseUrl}/support`.
  static String get supportUrl => _supportUrl.isNotEmpty
      ? _supportUrl
      : '$webBaseUrl/support';

  /// Deprecated alias — prefer [supportUrl].
  static String get supportWebsiteUrl => supportUrl;

  static String get privacyUrl => '$webBaseUrl/privacy';

  static String get termsUrl => '$webBaseUrl/terms';

  static String get guideUrl => '$webBaseUrl/guide';
}
