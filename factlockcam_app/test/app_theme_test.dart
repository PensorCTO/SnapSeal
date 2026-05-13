import 'package:flutter_test/flutter_test.dart';
import 'package:factlockcam/app/theme/app_colors.dart';
import 'package:factlockcam/app/theme/app_theme.dart';
import 'package:factlockcam/app/theme/app_typography.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('dark theme uses titanium and verified neon tokens', () {
    final theme = AppTheme.dark;

    expect(theme.scaffoldBackgroundColor, AppColors.titaniumDeep);
    expect(theme.colorScheme.primary, AppColors.verifiedNeon);
    expect(theme.colorScheme.tertiary, AppColors.kineticGreen);
  });

  test('mono helper resolves to Space Mono', () {
    final style = AppTextStyles.monoSm();

    expect(style.fontFamily, contains('Space'));
  });
}
