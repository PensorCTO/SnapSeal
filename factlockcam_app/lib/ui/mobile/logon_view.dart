import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/config/app_config.dart';
import '../../core/services/haptic_service.dart';
import '../../core/ui/widgets/heavy_metal_backdrop.dart';
import '../controllers/auth_controller.dart';

class LogonView extends ConsumerStatefulWidget {
  const LogonView({super.key});

  static const routePath = '/logon';

  @override
  ConsumerState<LogonView> createState() => _LogonViewState();
}

class _LogonViewState extends ConsumerState<LogonView>
    with HeavyMetalBackdropMixin<LogonView> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    return CupertinoPageScaffold(
      backgroundColor: Colors.transparent,
      child: Column(
        children: [
          const HeavyMetalLogoBanner(),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                BackgroundVideoLayer(
                  controller: backdropController,
                  ready: backdropReady,
                ),
                const TitaniumOverlay(),
                SafeArea(
                  top: false,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Lift the form above the software keyboard; UIKit may still
                      // log internal TUIKeyboard constraint warnings (benign).
                      final bottomInset =
                          MediaQuery.viewInsetsOf(context).bottom;
                      final contentMinHeight =
                          (constraints.maxHeight - bottomInset)
                              .clamp(0.0, double.infinity);
                      return SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: contentMinHeight,
                          ),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              24,
                              24,
                              24,
                              24 + bottomInset,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: _buildFormChildren(auth),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFormChildren(AuthUiState auth) {
    return [
      Text(
        'Authenticate with a 6-digit Magic Number. Untouchable media remains '
        'local.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 15,
          color: AppColors.starkWhite.withValues(alpha: 0.78),
        ),
      ),
      const SizedBox(height: 20),
      if (!AppConfig.hasSupabaseConfig) const _ConfigNotice(),
      CupertinoTextField(
        controller: _emailController,
        enabled: !auth.isLoading,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.email],
        placeholder: 'Email',
        placeholderStyle: TextStyle(
          color: AppColors.starkWhite.withValues(alpha: 0.45),
        ),
        style: const TextStyle(color: AppColors.starkWhite),
        cursorColor: AppColors.verifiedNeon,
        clearButtonMode: OverlayVisibilityMode.editing,
        decoration: _fieldDecoration(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      const SizedBox(height: 14),
      CupertinoButton(
        color: AppColors.verifiedNeon,
        disabledColor: AppColors.titaniumPanel,
        onPressed: auth.isLoading || !AppConfig.hasSupabaseConfig ? null : _sendOtp,
        child: auth.isLoading && !auth.otpSent
            ? const CupertinoActivityIndicator()
            : Text(
                auth.otpSent ? 'RESEND MAGIC NUMBER' : 'SEND MAGIC NUMBER',
                style: AppTextStyles.monoMd(color: AppColors.titaniumDeep),
              ),
      ),
      if (auth.otpSent) ...[
        const SizedBox(height: 12),
        Text(
          'Check your email for the 6-digit Magic Number.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.kineticGreen),
        ),
        const SizedBox(height: 12),
        CupertinoTextField(
          controller: _otpController,
          enabled: !auth.isLoading,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.oneTimeCode],
          placeholder: '6-digit code',
          placeholderStyle: TextStyle(
            color: AppColors.starkWhite.withValues(alpha: 0.45),
          ),
          style: AppTextStyles.monoLg(color: AppColors.starkWhite),
          cursorColor: AppColors.verifiedNeon,
          textAlign: TextAlign.center,
          maxLength: 6,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: _fieldDecoration(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          onSubmitted: (_) => _verifyOtp(),
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _otpController,
          builder: (context, otpValue, child) {
            final canVerify = _isSixDigitCode(otpValue.text);
            return CupertinoButton(
              color: AppColors.verifiedNeon,
              disabledColor: AppColors.titaniumPanel,
              onPressed: auth.isLoading || !canVerify ? null : _verifyOtp,
              child: auth.isLoading
                  ? const CupertinoActivityIndicator()
                  : child!,
            );
          },
          child: Text(
            'VERIFY MAGIC NUMBER',
            style: AppTextStyles.monoMd(color: AppColors.titaniumDeep),
          ),
        ),
      ],
      if (auth.error != null) ...[
        const SizedBox(height: 12),
        Text(
          auth.error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.alertAmber),
        ),
      ],
    ];
  }

  BoxDecoration _fieldDecoration() {
    return BoxDecoration(
      color: AppColors.titaniumPanel.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: AppColors.verifiedNeon.withValues(alpha: 0.4),
        width: 1,
      ),
    );
  }

  Future<void> _sendOtp() async {
    final haptics = ref.read(hapticServiceProvider);
    await haptics.tap();
    unawaited(playBackdropFromStart());
    _otpController.clear();
    final otpSent = await ref
        .read(authControllerProvider.notifier)
        .sendOtp(_emailController.text);
    if (otpSent) {
      await haptics.success();
    } else {
      await haptics.error();
    }
  }

  Future<void> _verifyOtp() async {
    final haptics = ref.read(hapticServiceProvider);
    await haptics.tap();
    unawaited(playBackdropFromStart());
    final verified = await ref
        .read(authControllerProvider.notifier)
        .verifyOtp(email: _emailController.text, token: _otpController.text);
    if (verified) {
      await haptics.success();
    } else {
      await haptics.error();
    }
  }

  bool _isSixDigitCode(String value) => RegExp(r'^\d{6}$').hasMatch(value);
}

class _ConfigNotice extends StatelessWidget {
  const _ConfigNotice();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.alertAmber.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.alertAmber.withValues(alpha: 0.55),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'Supabase is not configured yet. The local wallet shell is usable; '
          'Magic Number auth requires SUPABASE_URL and SUPABASE_ANON_KEY in '
          'repo-root `.env.local`, then run '
          '`bash scripts/sync_flutter_dart_defines.sh` from the repo root '
          '(or `../scripts/sync_flutter_dart_defines.sh` from factlockcam_app). '
          'After sync, plain `flutter run` works, or use '
          '`scripts/factlockcam_supabase_pipeline.sh app-run`.',
          style: TextStyle(
            color: AppColors.starkWhite.withValues(alpha: 0.88),
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
