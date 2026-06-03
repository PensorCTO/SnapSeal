import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Scaffold;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/di/service_providers.dart';
import '../../../core/legal/disclaimers.dart';

/// Bricked-state shell: import `.factlock` and rehydrate sovereign keys.
class RestoreArchiveView extends ConsumerStatefulWidget {
  const RestoreArchiveView({super.key});

  static const routePath = '/restore';

  @override
  ConsumerState<RestoreArchiveView> createState() => _RestoreArchiveViewState();
}

class _RestoreArchiveViewState extends ConsumerState<RestoreArchiveView> {
  bool _isRestoring = false;
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _passwordFocusNode.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _dismissKeyboard() async {
    _passwordFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  }

  Future<void> _pickAndRestore() async {
    await _dismissKeyboard();

    final password = _passwordController.text;
    if (password.isEmpty) {
      await _showMessage('Enter your backup password.');
      return;
    }

    final bytes =
        await ref.read(platformChannelCoordinatorProvider).pickFactlockBackupBytes();

    // Document picker can restore focus to the password field on iOS.
    await _dismissKeyboard();

    if (bytes == null || bytes.isEmpty) {
      return;
    }

    if (!mounted) return;
    setState(() => _isRestoring = true);
    try {
      await ref.read(walletBackupServiceProvider).importFactlock(
        fileBytes: bytes,
        backupPassword: password,
      );
      await ref.read(vaultServiceProvider).reloadVaultKey();
      _passwordController.clear();
      await _dismissKeyboard();
      await ref.read(keyCustodyProvider.notifier).refresh();
      // Navigation is handled by go_router redirect once custody is keysPresent.
    } catch (error) {
      if (!mounted) return;
      await _showMessage('Restore failed: $error');
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }

  Future<void> _showMessage(String message) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Restore Archive Keys'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.titaniumDeep,
      body: GestureDetector(
        onTap: _dismissKeyboard,
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: _isRestoring
              ? const Center(child: CupertinoActivityIndicator())
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      const Icon(
                        CupertinoIcons.lock_shield,
                        color: AppColors.kineticGreen,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ARCHIVE LOCKED',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.monoMd(
                          color: AppColors.starkWhite,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Cryptographic keys were removed from this device (Lock) or '
                        'the app was reinstalled. Import your .factlock backup and '
                        'enter your backup password. After reinstall, sign in with the '
                        'same email first, then import here to read cloud ciphertext.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.monoSm(
                          color: AppColors.starkWhite.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        restoreKeyCustodyDisclaimer,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.monoSm(
                          color: AppColors.starkWhite.withValues(alpha: 0.65),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      CupertinoTextField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        obscureText: true,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _pickAndRestore(),
                        placeholder: 'Backup password',
                        placeholderStyle: AppTextStyles.monoSm(
                          color: AppColors.starkWhite.withValues(alpha: 0.35),
                        ),
                        style: AppTextStyles.monoMd(color: AppColors.starkWhite),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.titaniumPanel,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.starkWhite.withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      CupertinoButton(
                        color: AppColors.kineticGreen,
                        onPressed: _pickAndRestore,
                        child: Text(
                          'IMPORT .FACTLOCK BACKUP',
                          style: AppTextStyles.monoSm(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(flex: 2),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
