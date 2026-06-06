import 'package:flutter/cupertino.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import 'archive_dispatch_preset_control.dart';
import 'dispatch_console_state.dart';

/// Access Control overlay inputs — Key, Lifespan, Exposure Limit.
class ArchiveAccessControlPanel extends StatelessWidget {
  const ArchiveAccessControlPanel({
    super.key,
    required this.passwordController,
    required this.passwordFocusNode,
    required this.obscurePassword,
    required this.onToggleObscurePassword,
    required this.maxDownloads,
    required this.linkTtlDays,
    required this.onMaxDownloadsChanged,
    required this.onLinkTtlChanged,
    this.compact = false,
    this.passwordEnabled = true,
    this.onPasswordSubmitted,
  });

  final TextEditingController passwordController;
  final FocusNode passwordFocusNode;
  final bool obscurePassword;
  final VoidCallback onToggleObscurePassword;
  final int maxDownloads;
  final int linkTtlDays;
  final ValueChanged<int> onMaxDownloadsChanged;
  final ValueChanged<int> onLinkTtlChanged;
  final bool compact;

  /// When false, Recipient Key is hidden until archive anchoring completes.
  final bool passwordEnabled;
  final VoidCallback? onPasswordSubmitted;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.titaniumPanel.withValues(alpha: 0.94),
        border: Border.all(
          color: AppColors.titaniumEdge.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ACCESS CONTROL PANEL',
              style: AppTextStyles.monoSm(
                color: AppColors.starkWhite.withValues(alpha: 0.55),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: compact ? 10 : 14),
            Text(
              'Recipient Key',
              style: AppTextStyles.monoSm(
                color: AppColors.starkWhite.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 8),
            if (!passwordEnabled)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.titaniumDeep,
                  border: Border.all(
                    color: AppColors.titaniumEdge.withValues(alpha: 0.8),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Text(
                    'Waiting for archive anchor…',
                    style: AppTextStyles.monoSm(
                      color: AppColors.starkWhite.withValues(alpha: 0.42),
                    ),
                  ),
                ),
              )
            else
              CupertinoTextField(
                controller: passwordController,
                focusNode: passwordFocusNode,
                autofocus: false,
                obscureText: obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onPasswordSubmitted?.call(),
                placeholder: 'Verifier password for recipient',
                style: AppTextStyles.monoSm(color: AppColors.starkWhite),
                placeholderStyle: AppTextStyles.monoSm(
                  color: AppColors.starkWhite.withValues(alpha: 0.35),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.titaniumDeep,
                  border: Border.all(
                    color: AppColors.titaniumEdge.withValues(alpha: 0.8),
                  ),
                ),
                suffix: CupertinoButton(
                  padding: const EdgeInsets.only(right: 8),
                  minimumSize: Size.zero,
                  onPressed: onToggleObscurePassword,
                  child: Icon(
                    obscurePassword
                        ? CupertinoIcons.eye_slash
                        : CupertinoIcons.eye,
                    size: 18,
                    color: AppColors.starkWhite.withValues(alpha: 0.55),
                  ),
                ),
              ),
            SizedBox(height: compact ? 12 : 16),
            Text(
              'Link Lifespan',
              style: AppTextStyles.monoSm(
                color: AppColors.starkWhite.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 8),
            ArchiveDispatchPresetControl(
              values: DispatchConsoleState.linkTtlPresets,
              selected: linkTtlDays,
              labelBuilder: (v) => '${v}d',
              onChanged: onLinkTtlChanged,
            ),
            SizedBox(height: compact ? 12 : 16),
            Text(
              'Exposure Limit',
              style: AppTextStyles.monoSm(
                color: AppColors.starkWhite.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 8),
            ArchiveDispatchPresetControl(
              values: DispatchConsoleState.maxDownloadPresets,
              selected: maxDownloads,
              labelBuilder: (v) => '$v',
              onChanged: onMaxDownloadsChanged,
            ),
          ],
        ),
      ),
    );
  }
}
