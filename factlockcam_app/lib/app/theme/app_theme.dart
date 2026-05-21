import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static final _textTheme = AppTextStyles.textTheme();

  static ThemeData get light => ThemeData(
    colorScheme: _lightScheme,
    scaffoldBackgroundColor: AppColors.titaniumDeep,
    textTheme: _textTheme,
    useMaterial3: true,
    brightness: Brightness.light,
    appBarTheme: _appBarTheme,
    cardTheme: _cardTheme,
    dividerTheme: _dividerTheme,
    textButtonTheme: _textButtonTheme,
  );

  static ThemeData get dark => ThemeData(
    colorScheme: _darkScheme,
    scaffoldBackgroundColor: AppColors.titaniumDeep,
    textTheme: _textTheme,
    useMaterial3: true,
    brightness: Brightness.dark,
    appBarTheme: _appBarTheme,
    cardTheme: _cardTheme,
    dividerTheme: _dividerTheme,
    textButtonTheme: _textButtonTheme,
  );

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.verifiedNeon,
    onPrimary: AppColors.titaniumDeep,
    secondary: AppColors.starkWhite,
    onSecondary: AppColors.titaniumDeep,
    tertiary: AppColors.kineticGreen,
    onTertiary: AppColors.titaniumDeep,
    error: Color(0xFFFF5A5F),
    onError: AppColors.titaniumDeep,
    surface: AppColors.titaniumDeep,
    onSurface: AppColors.starkWhite,
    surfaceContainerHighest: AppColors.titaniumPanel,
    outline: Color(0xFF5B5B5B),
    outlineVariant: AppColors.titaniumEdge,
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.verifiedNeon,
    onPrimary: AppColors.titaniumDeep,
    secondary: AppColors.starkWhite,
    onSecondary: AppColors.titaniumDeep,
    tertiary: AppColors.kineticGreen,
    onTertiary: AppColors.titaniumDeep,
    error: Color(0xFFFF5A5F),
    onError: AppColors.titaniumDeep,
    surface: AppColors.titaniumDeep,
    onSurface: AppColors.starkWhite,
    surfaceContainerHighest: AppColors.titaniumPanel,
    outline: Color(0xFF5B5B5B),
    outlineVariant: AppColors.titaniumEdge,
  );

  static final _appBarTheme = AppBarTheme(
    backgroundColor: AppColors.titaniumPanel,
    foregroundColor: AppColors.starkWhite,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: AppTextStyles.monoMd(color: AppColors.starkWhite),
  );

  static const _cardTheme = CardThemeData(
    color: AppColors.titaniumPanel,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(
      side: BorderSide(color: AppColors.titaniumEdge),
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  );

  static const _dividerTheme = DividerThemeData(
    color: AppColors.titaniumEdge,
    thickness: 1,
  );

  static final _textButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.verifiedNeon,
      textStyle: AppTextStyles.monoMd(color: AppColors.verifiedNeon),
    ),
  );
}
