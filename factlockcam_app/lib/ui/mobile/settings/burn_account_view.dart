import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Scaffold;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:postgrest/postgrest.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../vault/providers/thumbnail_cache_provider.dart';

/// Multi-step account burn with typed OBLITERATE confirmation.
class BurnAccountView extends ConsumerStatefulWidget {
  const BurnAccountView({super.key});

  static const routePath = '/burn-account';
  static const confirmationToken = 'OBLITERATE';

  @override
  ConsumerState<BurnAccountView> createState() => _BurnAccountViewState();
}

class _BurnAccountViewState extends ConsumerState<BurnAccountView> {
  bool _acknowledged = false;
  bool _isBurning = false;
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  bool get _canBurn =>
      _acknowledged &&
      _confirmController.text.trim().toUpperCase() ==
          BurnAccountView.confirmationToken;

  Future<void> _performBurn() async {
    if (!_canBurn) return;
    setState(() => _isBurning = true);
    try {
      await ref.read(authControllerProvider.notifier).performFullBurn();
      ref.invalidate(dashboardControllerProvider);
      ref.invalidate(thumbnailCacheProvider);
    } on PostgrestException catch (error) {
      if (!mounted) return;
      await _showAlert('Account deletion failed', error.message);
    } catch (error) {
      if (!mounted) return;
      await _showAlert('Account deletion failed', error.toString());
    } finally {
      if (mounted) {
        setState(() => _isBurning = false);
      }
    }
  }

  Future<void> _showAlert(String title, String message) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
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
    final auth = ref.watch(authControllerProvider);
    final busy = _isBurning || auth.isLoading;

    return Scaffold(
      backgroundColor: AppColors.titaniumDeep,
      appBar: CupertinoNavigationBar(
        backgroundColor: AppColors.titaniumPanel.withValues(alpha: 0.95),
        border: null,
        leading: CupertinoNavigationBarBackButton(
          color: AppColors.kineticGreen,
          onPressed: busy ? null : () => Navigator.of(context).pop(),
        ),
        middle: Text(
          'Burn Account',
          style: AppTextStyles.monoMd(color: AppColors.starkWhite),
        ),
      ),
      body: SafeArea(
        child: busy
            ? const Center(child: CupertinoActivityIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'PERMANENT ACCOUNT DESTRUCTION',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.monoMd(
                        color: CupertinoColors.destructiveRed,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Burning your account deletes all cloud assets, EVM ledger '
                      'references, and both local cryptographic keys on this device. '
                      'This action cannot be undone by a key restore.',
                      style: AppTextStyles.monoSm(
                        color: AppColors.starkWhite.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CupertinoCheckbox(
                          value: _acknowledged,
                          activeColor: AppColors.kineticGreen,
                          onChanged: (value) {
                            setState(() => _acknowledged = value ?? false);
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _acknowledged = !_acknowledged);
                            },
                            child: Text(
                              'I understand that cloud and local archive data will '
                              'be permanently destroyed and cannot be recovered.',
                              style: AppTextStyles.monoSm(
                                color: AppColors.starkWhite,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Type ${BurnAccountView.confirmationToken} to confirm',
                      style: AppTextStyles.monoSm(
                        color: AppColors.starkWhite.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    CupertinoTextField(
                      controller: _confirmController,
                      autocorrect: false,
                      enableSuggestions: false,
                      placeholder: BurnAccountView.confirmationToken,
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
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 28),
                    CupertinoButton(
                      color: CupertinoColors.destructiveRed,
                      disabledColor:
                          CupertinoColors.destructiveRed.withValues(alpha: 0.35),
                      onPressed: _canBurn ? _performBurn : null,
                      child: Text(
                        'BURN ACCOUNT PERMANENTLY',
                        style: AppTextStyles.monoSm(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
