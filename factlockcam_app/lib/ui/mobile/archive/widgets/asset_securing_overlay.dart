import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../providers/asset_lock_provider.dart';

/// Skeleton / spinner shown while an archive asset is under journal-backed lock.
class AssetSecuringOverlay extends ConsumerWidget {
  const AssetSecuringOverlay({
    super.key,
    required this.assetFingerprint,
    required this.child,
  });

  final String assetFingerprint;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locked = ref.watch(
      assetLockStateProvider.select((ids) => ids.contains(assetFingerprint)),
    );
    if (!locked) {
      return child;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        ColoredBox(
          color: AppColors.titaniumDeep.withValues(alpha: 0.72),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CupertinoActivityIndicator(
                  color: AppColors.kineticGreen,
                ),
                const SizedBox(height: 10),
                Text(
                  'SECURING FILE…',
                  style: AppTextStyles.monoSm(
                    color: AppColors.starkWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
