import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/haptic_service.dart';
import '../controllers/auth_controller.dart';

class LogonView extends ConsumerStatefulWidget {
  const LogonView({super.key});

  static const routePath = '/logon';

  @override
  ConsumerState<LogonView> createState() => _LogonViewState();
}

class _LogonViewState extends ConsumerState<LogonView> {
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
      navigationBar: const CupertinoNavigationBar(middle: Text('SnapSeal')),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Mathematical certainty wallet',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Authenticate with a 6-digit Magic Number. Untouchable media remains local.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                          const SizedBox(height: 28),
                          if (!auth.isConfigured) const _ConfigNotice(),
                          CupertinoTextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            placeholder: 'Email',
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                          ),
                          const SizedBox(height: 14),
                          CupertinoButton.filled(
                            onPressed: auth.isLoading ? null : _sendOtp,
                            child: auth.isLoading
                                ? const CupertinoActivityIndicator()
                                : const Text('Send Magic Number'),
                          ),
                          if (auth.otpSent) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'Check your email for the 6-digit Magic Number.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: CupertinoColors.activeGreen,
                              ),
                            ),
                            const SizedBox(height: 12),
                            CupertinoTextField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              autofillHints: const [AutofillHints.oneTimeCode],
                              placeholder: '6-digit code',
                              textAlign: TextAlign.center,
                              maxLength: 6,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              onSubmitted: (_) => _verifyOtp(),
                            ),
                            const SizedBox(height: 12),
                            CupertinoButton(
                              onPressed: auth.isLoading ? null : _verifyOtp,
                              child: const Text('Verify Magic Number'),
                            ),
                          ],
                          if (auth.error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              auth.error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: CupertinoColors.systemRed,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _sendOtp() async {
    final haptics = ref.read(hapticServiceProvider);
    await haptics.tap();
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
    final verified = await ref
        .read(authControllerProvider.notifier)
        .verifyOtp(email: _emailController.text, token: _otpController.text);
    if (verified) {
      await haptics.success();
    } else {
      await haptics.error();
    }
  }
}

class _ConfigNotice extends StatelessWidget {
  const _ConfigNotice();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CupertinoColors.systemYellow.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'Supabase is not configured yet. The local wallet shell is usable; '
          'Magic Number auth requires SUPABASE_URL and SUPABASE_ANON_KEY.',
          style: const TextStyle(color: CupertinoColors.label, fontSize: 13),
        ),
      ),
    );
  }
}
