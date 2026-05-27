import '../test/cloud_vault_e2e_test.dart' as smoke;

/// Device QA entrypoint — delegates to CI-safe smoke tests.
///
/// Run: `flutter test integration_test/cloud_vault_e2e_test.dart -d <ios-id>`
void main() => smoke.main();
