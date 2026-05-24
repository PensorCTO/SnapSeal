import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

/// Heavy-metal hardware-styled tile: titanium gradient surface, hairline
/// specular highlight along the top edge, Verified Neon outer stroke, and
/// mono uppercase label. Shared by the hub launcher and settings panels.
class HeavyMetalHubTile extends StatelessWidget {
  const HeavyMetalHubTile({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.compact = false,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;
  final bool compact;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveOnTap = enabled ? onTap : null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: '${label.toUpperCase()}. $subtitle',
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.titaniumHighlight,
                AppColors.titaniumPanel,
                Color(0xFF0A0A0A),
              ],
              stops: [0, 0.45, 1],
            ),
            border: Border.all(
              color: AppColors.verifiedNeon.withValues(alpha: 0.55),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.verifiedNeon.withValues(alpha: 0.08),
                blurRadius: 18,
                spreadRadius: 0.5,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: effectiveOnTap,
              splashColor: AppColors.verifiedNeon.withValues(alpha: 0.14),
              highlightColor: AppColors.verifiedNeon.withValues(alpha: 0.06),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 18,
                  vertical: compact ? 12 : 22,
                ),
                child: Row(
                  children: [
                    HeavyMetalHardwareIcon(icon: icon, compact: compact),
                    SizedBox(width: compact ? 10 : 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label.toUpperCase(),
                            style: compact
                                ? AppTextStyles.monoSm(
                                    color: AppColors.starkWhite,
                                  )
                                : AppTextStyles.monoMd(
                                    color: AppColors.starkWhite,
                                  ),
                            maxLines: compact ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: compact ? 2 : 3,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.starkWhite.withValues(alpha: 0.62),
                              fontSize: compact ? 11 : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: compact ? 20 : 24,
                      color: AppColors.titaniumHighlight,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HeavyMetalHardwareIcon extends StatelessWidget {
  const HeavyMetalHardwareIcon({super.key, required this.icon, this.compact = false});

  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 40.0 : 52.0;
    final iconSize = compact ? 20.0 : 26.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFF1F1F1F), Color(0xFF0A0A0A)],
          stops: [0.4, 1],
        ),
        border: Border.all(
          color: AppColors.verifiedNeon.withValues(alpha: 0.75),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.verifiedNeon.withValues(alpha: 0.18),
            blurRadius: 10,
          ),
        ],
      ),
      child: Icon(icon, size: iconSize, color: AppColors.verifiedNeon),
    );
  }
}
