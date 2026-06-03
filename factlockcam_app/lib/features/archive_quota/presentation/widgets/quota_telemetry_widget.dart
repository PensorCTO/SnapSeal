import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../ui/controllers/auth_controller.dart';
import '../../domain/models/archive_quota_snapshot.dart';
import '../../domain/models/quota_alert_level.dart';
import '../providers/archive_quota_provider.dart';

/// Dual progress bars for Archive storage and egress telemetry.
class QuotaTelemetryWidget extends ConsumerStatefulWidget {
  const QuotaTelemetryWidget({super.key});

  @override
  ConsumerState<QuotaTelemetryWidget> createState() =>
      _QuotaTelemetryWidgetState();
}

class _QuotaTelemetryWidgetState extends ConsumerState<QuotaTelemetryWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(archiveQuotaNotifierProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final quotaAsync = ref.watch(archiveQuotaNotifierProvider);
    final isAuthenticated =
        ref.watch(authStateProvider).asData?.value?.session != null;

    return RepaintBoundary(
      child: quotaAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (error, _) => _QuotaTelemetryPlaceholder(
          message: kDebugMode
              ? 'QUOTA RPC: $error'
              : null,
        ),
        data: (snapshot) {
          if (snapshot != null) {
            return _QuotaTelemetryBody(snapshot: snapshot);
          }
          if (kDebugMode && isAuthenticated) {
            return const _QuotaTelemetryPlaceholder(
              message: 'QUOTA: no snapshot (check RPC / migration)',
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

/// Debug-only hint when quota telemetry cannot load.
class _QuotaTelemetryPlaceholder extends StatelessWidget {
  const _QuotaTelemetryPlaceholder({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode || message == null || message!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        message!,
        style: AppTextStyles.monoSm(color: AppColors.alertAmber),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _QuotaTelemetryBody extends StatelessWidget {
  const _QuotaTelemetryBody({required this.snapshot});

  final ArchiveQuotaSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final alert = snapshot.alertLevel;
    final accent = _accentFor(alert);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.titaniumPanel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.titaniumEdge),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'ARCHIVE QUOTA',
                    style: AppTextStyles.monoSm(
                      color: AppColors.starkWhite.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    snapshot.tier.displayName.toUpperCase(),
                    style: AppTextStyles.monoSm(color: accent),
                  ),
                ],
              ),
              if (alert != QuotaAlertLevel.normal) ...[
                const SizedBox(height: 6),
                Text(
                  _alertCopy(alert),
                  style: AppTextStyles.monoSm(color: accent),
                ),
              ],
              const SizedBox(height: 10),
              _QuotaBar(
                label: 'STORAGE',
                ratio: snapshot.storageUsageRatio,
                usedLabel: _formatBytes(snapshot.storageUsedBytes),
                limitLabel: _formatBytes(snapshot.tier.storageLimitBytes),
                accent: accent,
              ),
              const SizedBox(height: 8),
              _QuotaBar(
                label: 'EGRESS',
                ratio: snapshot.egressUsageRatio,
                usedLabel: _formatBytes(snapshot.egressUsedBytes),
                limitLabel: _formatBytes(snapshot.tier.egressLimitBytes),
                accent: accent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _accentFor(QuotaAlertLevel level) {
    return switch (level) {
      QuotaAlertLevel.normal => AppColors.kineticGreen,
      QuotaAlertLevel.warning80 => AppColors.alertAmber,
      QuotaAlertLevel.critical95 => AppColors.verifiedNeon,
      QuotaAlertLevel.blocked => AppColors.verifiedNeon,
    };
  }

  static String _alertCopy(QuotaAlertLevel level) {
    return switch (level) {
      QuotaAlertLevel.warning80 => 'Approaching Archive capacity (80%+).',
      QuotaAlertLevel.critical95 => 'Critical Archive capacity (95%+).',
      QuotaAlertLevel.blocked => 'Archive limit reached — upgrade to continue.',
      QuotaAlertLevel.normal => '',
    };
  }

  static String _formatBytes(int bytes) {
    if (bytes >= 1073741824) {
      return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1048576) {
      return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
}

class _QuotaBar extends StatelessWidget {
  const _QuotaBar({
    required this.label,
    required this.ratio,
    required this.usedLabel,
    required this.limitLabel,
    required this.accent,
  });

  final String label;
  final double ratio;
  final String usedLabel;
  final String limitLabel;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final clamped = ratio.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppTextStyles.monoSm(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '$usedLabel / $limitLabel',
              style: AppTextStyles.monoSm(),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: 4,
            backgroundColor: AppColors.titaniumEdge,
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
      ],
    );
  }
}
