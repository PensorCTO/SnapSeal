import 'dart:async';

import 'package:factlockcam/app/theme/app_typography.dart';
import 'package:factlockcam/core/ui/widgets/heavy_metal_backdrop.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AppTextStyles.useGoogleFonts = false;
  GoogleFonts.config.allowRuntimeFetching = false;
  // Widget tests must not touch the real video_player platform channel.
  HeavyMetalBackdropMixin.enabled = false;
  await testMain();
}
