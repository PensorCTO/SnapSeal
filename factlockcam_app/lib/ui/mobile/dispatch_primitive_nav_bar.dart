import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/haptic_service.dart';

/// Tri-state global navigation primitive: CAPTURE, ARCHIVE, DISPATCH CONSOLE.
class DispatchPrimitiveNavBar extends ConsumerWidget {
  const DispatchPrimitiveNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  static const labels = ['CAPTURE', 'ARCHIVE', 'DISPATCH CONSOLE'];

  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.titaniumPanel,
          border: Border(
            top: BorderSide(
              color: AppColors.verifiedNeon.withValues(alpha: 0.35),
              width: 0.6,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SizedBox(
            height: 52,
            child: Row(
              children: List.generate(labels.length, (index) {
                final selected = index == currentIndex;
                return Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (index == currentIndex) return;
                        unawaited(ref.read(hapticServiceProvider).lock());
                        onTabSelected(index);
                      },
                      child: Center(
                        child: Text(
                          labels[index],
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.monoSm(
                            color: selected
                                ? AppColors.kineticGreen
                                : AppColors.starkWhite.withValues(alpha: 0.45),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
