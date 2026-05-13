import 'dart:async';

import 'package:factlockcam/app/theme/app_typography.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AppTextStyles.useGoogleFonts = false;
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
