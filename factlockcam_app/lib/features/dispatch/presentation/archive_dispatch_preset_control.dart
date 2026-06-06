import 'package:flutter/cupertino.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

/// Segmented preset picker for dispatch policy values.
class ArchiveDispatchPresetControl extends StatelessWidget {
  const ArchiveDispatchPresetControl({
    super.key,
    required this.values,
    required this.selected,
    required this.labelBuilder,
    required this.onChanged,
  });

  final List<int> values;
  final int selected;
  final String Function(int) labelBuilder;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return CupertinoSlidingSegmentedControl<int>(
      groupValue: selected,
      backgroundColor: AppColors.titaniumDeep,
      thumbColor: AppColors.kineticGreen.withValues(alpha: 0.25),
      children: {
        for (final value in values)
          value: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              labelBuilder(value),
              style: AppTextStyles.monoSm(
                color: value == selected
                    ? AppColors.kineticGreen
                    : AppColors.starkWhite.withValues(alpha: 0.55),
                fontWeight:
                    value == selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
      },
      onValueChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}
