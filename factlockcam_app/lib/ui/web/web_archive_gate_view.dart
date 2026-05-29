import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/config/app_config.dart';

/// Minimal landing for the archive subdomain when no courier package is linked.
///
/// Production web on `archive.factlockcam.com` is **courier unlock only** — not a
/// browser edition of the mobile app. Origination stays on native iOS/Android.
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
                    'COURIER UNLOCK ONLY',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.monoSm(
                      color: AppColors.kineticGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'This address unlocks password-protected Send Proof packages '
                    'shared with you. Open the full link from your sender — it '
                    'includes a package id in the URL.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.monoSm(
                      color: AppColors.starkWhite.withValues(alpha: 0.62),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Capture, seal, and archive origination require the native '
                    'iOS or Android application with hardware-backed attestation.',
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
