import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/config/app_config.dart';

/// Minimal landing for the archive subdomain web bundle.
///
/// Production web on `archive.factlockcam.com` points recipients and visitors
/// to the native app and marketing site. Courier unlock was decommissioned in
/// favor of local Certificate Studio on iOS and Android.
class WebArchiveGateView extends StatelessWidget {
  const WebArchiveGateView({super.key});

  static const routePath = '/';

  static Uri get _marketingSite {
    final base = AppConfig.webBaseUrl.trim();
    if (base.isNotEmpty) {
      return Uri.parse(base);
    }
    return Uri.parse('https://factlockcam.com');
  }

  Future<void> _openMarketingSite() async {
    final uri = _marketingSite;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw StateError('Could not open $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.titaniumDeep,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'FactLockCam Archive',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.monoLg(
                      color: AppColors.verifiedNeon,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'CERTIFICATE STUDIO · NATIVE APP',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.monoSm(
                      color: AppColors.kineticGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Archive origination, sealing, and tamper-proof certificates '
                    'run on the native iOS and Android application with '
                    'hardware-backed attestation and a local-first encrypted archive.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.monoSm(
                      color: AppColors.starkWhite.withValues(alpha: 0.62),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Password-protected courier links are no longer offered. '
                    'Use Certificate Studio in the app to edit metadata, preview, '
                    'print, or share a certificate PDF directly from your device.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.monoSm(
                      color: AppColors.starkWhite.withValues(alpha: 0.42),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: _openMarketingSite,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.kineticGreen,
                      foregroundColor: AppColors.titaniumDeep,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Learn about FactLockCam',
                      style: AppTextStyles.monoSm(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
