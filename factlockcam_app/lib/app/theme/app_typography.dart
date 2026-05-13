import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  static bool useGoogleFonts = true;

  static TextTheme textTheme() {
    final base = ThemeData.dark().textTheme;
    final textTheme = useGoogleFonts
        ? GoogleFonts.interTextTheme(base)
        : base.apply(fontFamily: 'Inter');
    return textTheme.apply(
      bodyColor: AppColors.starkWhite.withValues(alpha: 0.86),
      displayColor: AppColors.starkWhite,
    );
  }

  static TextStyle monoSm({
    Color? color,
    FontWeight? fontWeight,
    double? height,
  }) {
    return _spaceMono(
      fontSize: 10.5,
      color: color ?? AppColors.starkWhite.withValues(alpha: 0.8),
      fontWeight: fontWeight,
      height: height ?? 1.25,
      letterSpacing: 0.2,
    );
  }

  static TextStyle monoMd({
    Color? color,
    FontWeight? fontWeight,
    double? height,
  }) {
    return _spaceMono(
      fontSize: 13,
      color: color ?? AppColors.starkWhite.withValues(alpha: 0.88),
      fontWeight: fontWeight ?? FontWeight.w600,
      height: height ?? 1.25,
      letterSpacing: 0.6,
    );
  }

  static TextStyle monoLg({
    Color? color,
    FontWeight? fontWeight,
    double? height,
  }) {
    return _spaceMono(
      fontSize: 18,
      color: color ?? AppColors.starkWhite,
      fontWeight: fontWeight ?? FontWeight.w700,
      height: height ?? 1.18,
      letterSpacing: 0.8,
    );
  }

  static TextStyle _spaceMono({
    required double fontSize,
    required Color color,
    required FontWeight? fontWeight,
    required double height,
    required double letterSpacing,
  }) {
    if (useGoogleFonts) {
      return GoogleFonts.spaceMono(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
      );
    }
    return TextStyle(
      fontFamily: 'Space Mono',
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}
