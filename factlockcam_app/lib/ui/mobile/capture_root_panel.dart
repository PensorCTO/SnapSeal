import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../web/web_capture_disabled_panel.dart';
import 'camera/acquisition_mode.dart';
import 'camera/capture_panel.dart';

/// Root CAPTURE tab — Photo/Video mode switch with PR0 lazy camera mount.
class CaptureRootPanel extends StatelessWidget {
  const CaptureRootPanel({
    super.key,
    required this.isActive,
    required this.selectedMode,
    required this.onModeChanged,
  });

  /// When false, camera hardware is not mounted (IndexedStack sibling tabs).
  final bool isActive;

  final AcquisitionMode selectedMode;
  final ValueChanged<AcquisitionMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return WebCaptureDisabledPanel(onBackToHub: _noop);
    }

    return Column(
      children: [
        _CaptureModeSelector(
          selectedMode: selectedMode,
          onModeChanged: onModeChanged,
        ),
        Expanded(
          child: isActive
              ? _lazyCamera(selectedMode)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _lazyCamera(AcquisitionMode mode) {
    return buildCapturePanel(
      key: ValueKey('camera_${mode.name}'),
      mode: mode,
      onBackToHub: _noop,
    );
  }

  static void _noop() {}
}

class _CaptureModeSelector extends StatelessWidget {
  const _CaptureModeSelector({
    required this.selectedMode,
    required this.onModeChanged,
  });

  final AcquisitionMode selectedMode;
  final ValueChanged<AcquisitionMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.titaniumDeep,
        border: Border(
          bottom: BorderSide(
            color: AppColors.verifiedNeon.withValues(alpha: 0.35),
            width: 0.6,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 8),
        child: CupertinoSlidingSegmentedControl<AcquisitionMode>(
          groupValue: selectedMode,
          thumbColor: AppColors.titaniumPanel,
          backgroundColor: AppColors.titaniumPanel.withValues(alpha: 0.6),
          children: {
            AcquisitionMode.photo: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                'PICTURE',
                style: AppTextStyles.monoSm(
                  color: selectedMode == AcquisitionMode.photo
                      ? AppColors.kineticGreen
                      : AppColors.starkWhite.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            AcquisitionMode.video: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                'VIDEO',
                style: AppTextStyles.monoSm(
                  color: selectedMode == AcquisitionMode.video
                      ? AppColors.kineticGreen
                      : AppColors.starkWhite.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          },
          onValueChanged: (value) {
            if (value != null) onModeChanged(value);
          },
        ),
      ),
    );
  }
}
