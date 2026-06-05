import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/config/app_config.dart';
import '../../../core/marketing/approved_pitch.dart';

class ViralLoopOverlay extends StatelessWidget {
  const ViralLoopOverlay({
    super.key,
    required this.onDismiss,
  });

  final VoidCallback onDismiss;

  static Uri get _appStoreUri {
    const fromEnv = String.fromEnvironment('APP_STORE_URL');
    if (fromEnv.isNotEmpty) {
      return Uri.parse(fromEnv);
    }
    final generated = AppConfig.appStoreUrl;
    if (generated.isNotEmpty) {
      return Uri.parse(generated);
    }
    return Uri.parse(AppConfig.webBaseUrl);
  }

  Future<void> _openAppStore() async {
    final uri = _appStoreUri;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw StateError('Could not open $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                color: AppColors.titaniumDeep.withValues(alpha: 0.72),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    mechanismTagline,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.monoLg(color: AppColors.verifiedNeon),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    courierConsoleViralPitch,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.monoSm(
                      color: AppColors.starkWhite.withValues(alpha: 0.78),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _openAppStore,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.kineticGreen,
                      foregroundColor: AppColors.titaniumDeep,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text(
                      'Get FactLockCam',
                      style: AppTextStyles.monoSm(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: onDismiss,
                    child: Text(
                      'Continue viewing',
                      style: AppTextStyles.monoSm(
                        color: AppColors.starkWhite.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
