import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/di/service_providers.dart';
import '../../archive_quota/presentation/widgets/quota_telemetry_widget.dart';

/// Real-time Archive byte telemetry + credit gas gauge for Secure Comm capture.
class SecureCommConsumptionPanel extends ConsumerWidget {
  const SecureCommConsumptionPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quota = ref.watch(quotaStateProvider);
    final proofsLine = quota == null
        ? null
        : 'PROOFS: ${quota.proProofsRemaining}/${quota.proProofsBase}';

    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (proofsLine != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(
                proofsLine,
                style: AppTextStyles.monoSm(
                  color: AppColors.kineticGreen.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const QuotaTelemetryWidget(),
        ],
      ),
    );
  }
}
