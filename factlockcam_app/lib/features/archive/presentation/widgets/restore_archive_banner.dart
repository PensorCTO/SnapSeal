import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';

class RestoreArchiveBanner extends StatelessWidget {
  const RestoreArchiveBanner({
    super.key,
    required this.onRestoreTap,
  });

  final VoidCallback onRestoreTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.titaniumPanel,
      child: InkWell(
        onTap: onRestoreTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.arrow_down_doc,
                color: AppColors.kineticGreen,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                'Restore Digital Archive',
                textAlign: TextAlign.center,
                style: AppTextStyles.monoSm(color: AppColors.starkWhite),
              ),
              const SizedBox(height: 4),
              Text(
                'Import encrypted backup to rehydrate this asset.',
                textAlign: TextAlign.center,
                style: AppTextStyles.monoSm(
                  color: AppColors.starkWhite.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
