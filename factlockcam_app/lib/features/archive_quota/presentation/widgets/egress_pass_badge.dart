import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../presentation/providers/quota_state_provider.dart';

/// Pill badge showing consumable Egress Pass verification credits.
class EgressPassBadge extends ConsumerWidget {
  const EgressPassBadge({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quota = ref.watch(quotaStateProvider);
    if (quota == null) {
      return const SizedBox.shrink();
    }

    final accent = quota.hasVerificationCredits
        ? AppColors.kineticGreen
        : AppColors.verifiedNeon;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, compact ? 2 : 4, 16, 0),
      child: Align(
        alignment: Alignment.centerRight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.titaniumPanel,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.titaniumEdge),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              'Egress Pass · ${quota.egressCreditsBalance} credits',
              style: AppTextStyles.monoSm(color: accent, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
