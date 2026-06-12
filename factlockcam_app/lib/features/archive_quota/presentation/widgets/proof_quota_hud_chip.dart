import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../interceptors/archive_quota_block_reason.dart';
import '../interceptors/archive_quota_paywall.dart';
import '../providers/quota_state_provider.dart';

/// Critical-system readout of remaining pro proofs, surfaced inside the camera
/// HUD. Pulses when proofs are nearly exhausted to organically drive the user
/// toward the subscription upgrade, and opens the paywall on tap.
///
/// Reads the credit layer ([quotaStateProvider]) passively — quota state never
/// blocks the camera isolate or shutter animation frames.
class ProofQuotaHudChip extends ConsumerStatefulWidget {
  const ProofQuotaHudChip({super.key});

  /// Remaining count at or below this triggers the warning (pulsing) state.
  static const warningThreshold = 1;

  @override
  ConsumerState<ProofQuotaHudChip> createState() => _ProofQuotaHudChipState();
}

class _ProofQuotaHudChipState extends ConsumerState<ProofQuotaHudChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _syncPulse({required bool warning}) {
    if (warning) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else if (_pulseController.isAnimating || _pulseController.value != 0) {
      _pulseController
        ..stop()
        ..value = 0;
    }
  }

  Future<void> _openPaywall() {
    return presentArchiveQuotaPaywall(
      context,
      ref,
      reason: ArchiveQuotaBlockReason.storage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final quota = ref.watch(quotaStateProvider);
    if (quota == null) {
      _syncPulse(warning: false);
      return const SizedBox.shrink();
    }

    final remaining = quota.proProofsRemaining;
    final base = quota.proProofsBase;
    final warning = remaining <= ProofQuotaHudChip.warningThreshold;
    _syncPulse(warning: warning);

    final accent = warning ? AppColors.alertAmber : AppColors.verifiedNeon;

    return RepaintBoundary(
      child: Semantics(
        button: true,
        label: 'Proofs remaining $remaining of $base. Tap to upgrade.',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openPaywall,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final pulse = warning ? _pulseController.value : 0.0;
              return Opacity(
                opacity: 0.85 + 0.15 * pulse,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.titaniumPanel.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.55 + 0.45 * pulse),
                      width: 1,
                    ),
                  ),
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PROOFS REMAINING: $remaining/$base',
                    style: AppTextStyles.monoSm(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (warning) ...[
                    const SizedBox(width: 6),
                    Text(
                      'UPGRADE',
                      style: AppTextStyles.monoSm(
                        color: AppColors.starkWhite.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
