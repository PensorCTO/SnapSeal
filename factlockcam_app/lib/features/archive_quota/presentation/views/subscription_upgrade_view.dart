import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/legal/disclaimers.dart';
import '../interceptors/archive_quota_block_reason.dart';
import '../providers/subscription_upgrade_provider.dart';

/// Enterprise subscription paywall for Archive tier upgrades.
class SubscriptionUpgradeView extends ConsumerWidget {
  const SubscriptionUpgradeView({
    super.key,
    required this.blockReason,
  });

  final ArchiveQuotaBlockReason blockReason;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upgradeAsync = ref.watch(subscriptionUpgradeProvider);
    final busy = upgradeAsync.isLoading;

    return SafeArea(
      child: Material(
        color: AppColors.titaniumDeep,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Upgrade Archive',
                style: AppTextStyles.monoMd(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _reasonCopy(blockReason),
                style: AppTextStyles.monoSm(
                  color: AppColors.starkWhite.withValues(alpha: 0.75),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                archiveSubscriptionTierDisclaimer,
                style: AppTextStyles.monoSm(
                  color: AppColors.starkWhite.withValues(alpha: 0.65),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _TierCard(
                title: 'Intro Week',
                priceLabel: '\$0.99 first week',
                proofLabel: '25 seals',
                detailLabel: 'Try sealing for one week',
                badge: 'INTRO',
                busy: busy,
                onUpgrade: () => _upgrade(ref, 'picture'),
              ),
              const SizedBox(height: 10),
              _TierCard(
                title: 'Weekly',
                priceLabel: '\$4.99 / week',
                proofLabel: 'Ongoing proof access',
                detailLabel: 'Renews weekly after the intro week',
                busy: busy,
                onUpgrade: () => _upgrade(ref, 'picture'),
              ),
              const SizedBox(height: 10),
              _TierCard(
                title: 'Annual',
                priceLabel: '\$49.99 / year',
                proofLabel: '500 proofs / year',
                detailLabel: 'Best value — save vs. weekly',
                badge: 'BEST VALUE',
                busy: busy,
                onUpgrade: () => _upgrade(ref, 'video'),
              ),
              const SizedBox(height: 16),
              CupertinoButton(
                onPressed: busy ? null : () => Navigator.of(context).pop(),
                child: Text(
                  'Not now',
                  style: AppTextStyles.monoSm(
                    color: AppColors.starkWhite.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _reasonCopy(ArchiveQuotaBlockReason reason) {
    return switch (reason) {
      ArchiveQuotaBlockReason.storage =>
        'You have used all of your sealing proofs. Subscribe to keep sealing.',
      ArchiveQuotaBlockReason.egress =>
        'You have used your verification credits. Subscribe for more proofs.',
      ArchiveQuotaBlockReason.singleCapture =>
        'Free captures are limited to 50 MB. Subscribe for full-length proofs.',
    };
  }

  Future<void> _upgrade(WidgetRef ref, String tierId) async {
    try {
      await ref.read(subscriptionUpgradeProvider.notifier).upgrade(tierId);
    } catch (_) {
      return;
    }
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.title,
    required this.priceLabel,
    required this.proofLabel,
    required this.detailLabel,
    required this.busy,
    required this.onUpgrade,
    this.badge,
  });

  final String title;
  final String priceLabel;
  final String proofLabel;
  final String detailLabel;
  final bool busy;
  final VoidCallback onUpgrade;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.titaniumPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.titaniumEdge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: AppTextStyles.monoMd(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.verifiedNeon),
                    ),
                    child: Text(
                      badge!,
                      style: AppTextStyles.monoSm(
                        color: AppColors.verifiedNeon,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              priceLabel,
              style: AppTextStyles.monoSm(color: AppColors.kineticGreen),
            ),
            const SizedBox(height: 6),
            Text(
              proofLabel,
              style: AppTextStyles.monoSm(fontWeight: FontWeight.w600),
            ),
            Text(
              detailLabel,
              style: AppTextStyles.monoSm(
                color: AppColors.starkWhite.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                color: AppColors.kineticGreen,
                padding: const EdgeInsets.symmetric(vertical: 10),
                onPressed: busy ? null : onUpgrade,
                child: busy
                    ? const CupertinoActivityIndicator(color: AppColors.titaniumDeep)
                    : Text(
                        'Choose $title',
                        style: AppTextStyles.monoSm(
                          color: AppColors.titaniumDeep,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
