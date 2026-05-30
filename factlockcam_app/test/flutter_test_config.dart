import 'dart:async';

import 'package:factlockcam/app/theme/app_typography.dart';
import 'package:factlockcam/core/ui/widgets/heavy_metal_backdrop.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'helpers/mock_platform_interfaces.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AppTextStyles.useGoogleFonts = false;
  GoogleFonts.config.allowRuntimeFetching = false;
  VideoPlayerPlatform.instance = MockVideoPlayerPlatform();
  // Widget tests must not touch the real video_player platform channel.
  HeavyMetalBackdropMixin.enabled = false;
  await testMain();
}
