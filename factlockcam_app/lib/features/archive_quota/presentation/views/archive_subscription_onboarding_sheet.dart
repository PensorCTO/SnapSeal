import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/legal/disclaimers.dart';
import '../../../../core/ui/widgets/legal_disclosure_text.dart';

const _onboardingSeenKey = 'archive_subscription_onboarding_seen_v1';

/// Whether the first-run Archive subscription onboarding was dismissed.
Future<bool> archiveSubscriptionOnboardingSeen() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_onboardingSeenKey) ?? false;
}

Future<void> markArchiveSubscriptionOnboardingSeen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_onboardingSeenKey, true);
}

/// Presents one-time onboarding after logon (Archive tiers + legal boundaries).
Future<void> showArchiveSubscriptionOnboardingIfNeeded(
  BuildContext context,
) async {
  if (await archiveSubscriptionOnboardingSeen()) {
    return;
  }
  if (!context.mounted) return;
  await showCupertinoModalPopup<void>(
    context: context,
    builder: (sheetContext) => const ArchiveSubscriptionOnboardingSheet(),
  );
}

/// First-run disclosure: epistemic boundary, key custody, subscription limits.
class ArchiveSubscriptionOnboardingSheet extends StatelessWidget {
  const ArchiveSubscriptionOnboardingSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        color: AppColors.titaniumDeep,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Archive & Subscriptions',
                style: AppTextStyles.monoMd(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              LegalDisclosureColumn(paragraphs: archiveOnboardingParagraphs),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _openUrl(AppConfig.termsUrl),
                      child: Text(
                        'Terms',
                        style: AppTextStyles.monoSm(color: AppColors.kineticGreen),
                      ),
                    ),
                  ),
                  Expanded(
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _openUrl(AppConfig.privacyUrl),
                      child: Text(
                        'Privacy',
                        style: AppTextStyles.monoSm(color: AppColors.kineticGreen),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CupertinoButton.filled(
                color: AppColors.kineticGreen,
                onPressed: () async {
                  await markArchiveSubscriptionOnboardingSeen();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: Text(
                  'Continue',
                  style: AppTextStyles.monoSm(
                    color: AppColors.titaniumDeep,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
