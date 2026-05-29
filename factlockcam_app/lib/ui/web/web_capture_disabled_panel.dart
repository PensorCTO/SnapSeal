import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/ui/widgets/vault_panel_navigation_bar.dart';

/// Read-only placeholder shown on web where native camera capture would appear.
///
/// Lens-to-cloud capture requires Secure Enclave / Keystore attestation and is
/// exclusive to the native iOS and Android applications.
class WebCaptureDisabledPanel extends StatelessWidget {
  const WebCaptureDisabledPanel({super.key, required this.onBackToHub});

  final VoidCallback onBackToHub;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.titaniumDeep,
      appBar: VaultPanelNavigationBar(
        title: 'Capture',
        onBack: onBackToHub,
        heroTag: 'web_capture_disabled_nav',
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.camera_fill,
                size: 56,
                color: AppColors.starkWhite.withValues(alpha: 0.28),
              ),
              const SizedBox(height: 20),
              Text(
                'CAPTURE UNAVAILABLE',
                textAlign: TextAlign.center,
                style: AppTextStyles.monoMd(
                  color: AppColors.starkWhite.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Capture is disabled in the browser. Please use the native '
                'iOS/Android application to capture securely authenticated media.',
                textAlign: TextAlign.center,
                style: AppTextStyles.monoSm(
                  color: AppColors.starkWhite.withValues(alpha: 0.42),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
