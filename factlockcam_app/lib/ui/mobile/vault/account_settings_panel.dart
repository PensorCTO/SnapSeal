import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, Scaffold;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:postgrest/postgrest.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/config/app_config.dart';
import '../../../core/ui/widgets/heavy_metal_backdrop.dart';
import '../../../core/ui/widgets/heavy_metal_hub_tile.dart';
import '../../../core/ui/widgets/vault_panel_navigation_bar.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../settings/legal_document_view.dart';
import 'providers/thumbnail_cache_provider.dart';

/// Account & Settings panel — logout, account deletion, legal links.
class AccountSettingsPanel extends ConsumerStatefulWidget {
  const AccountSettingsPanel({super.key, this.onBackToHub});

  final VoidCallback? onBackToHub;

  @override
  ConsumerState<AccountSettingsPanel> createState() =>
      _AccountSettingsPanelState();
}

class _AccountSettingsPanelState extends ConsumerState<AccountSettingsPanel>
    with HeavyMetalBackdropMixin<AccountSettingsPanel> {
  bool _isBurning = false;

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      if (!mounted) return;
      await _showAlert('Unable to open link', url);
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openSupportWebsite() => _openExternalUrl(AppConfig.supportUrl);

  void _openLegalDocument({
    required String title,
    required String assetPath,
  }) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => LegalDocumentView(title: title, assetPath: assetPath),
      ),
    );
  }

  Future<void> _showComingSoon(String feature) {
    return _showAlert(
      'Coming soon',
      '$feature will be available in a future update.',
    );
  }

  Future<void> _signOut() async {
    await ref.read(authControllerProvider.notifier).signOut();
    ref.invalidate(dashboardControllerProvider);
    ref.invalidate(thumbnailCacheProvider);
  }

  Future<void> _confirmBurnAccount() async {
    final first = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your account, remote proof data, '
          'and courier packages. Local archive data on this device will also '
          'be erased. This cannot be undone.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (first != true || !mounted) return;

    final second = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Final confirmation'),
        content: const Text(
          'Tap Delete Account to permanently remove your FactLockCam '
          'account and all associated server data.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
    if (second != true || !mounted) return;

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
      body: Column(
        children: [
          if (widget.onBackToHub != null)
            VaultPanelNavigationBar(
              title: 'Account',
              onBack: widget.onBackToHub!,
            ),
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
                  child: busy
                      ? const Center(child: CupertinoActivityIndicator())
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight - 40,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'ACCOUNT & SETTINGS',
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.monoMd(
                                        color: AppColors.starkWhite,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    _ActionButton(
                                      label: 'Log out',
                                      color: AppColors.kineticGreen,
                                      onPressed: busy ? null : _signOut,
                                    ),
                                    const SizedBox(height: 12),
                                    _ActionButton(
                                      label: 'Burn account',
                                      color: CupertinoColors.destructiveRed,
                                      onPressed: busy ? null : _confirmBurnAccount,
                                    ),
                                    const SizedBox(height: 28),
                                    _SectionLabel('LEGAL & SUPPORT'),
                                    const SizedBox(height: 12),
                                    HeavyMetalHubTile(
                                      icon: Icons.description_outlined,
                                      label: 'Terms of Service',
                                      subtitle: 'End-user license and usage terms',
                                      onTap: () => _openLegalDocument(
                                        title: 'Terms of Service',
                                        assetPath: LegalDocumentView.termsAssetPath,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    HeavyMetalHubTile(
                                      icon: Icons.shield_outlined,
                                      label: 'Privacy Policy',
                                      subtitle: 'How we handle your data on this device',
                                      onTap: () => _openLegalDocument(
                                        title: 'Privacy Policy',
                                        assetPath:
                                            LegalDocumentView.privacyAssetPath,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    HeavyMetalHubTile(
                                      icon: Icons.help_outline,
                                      label: 'Help & Support',
                                      subtitle: 'Contact support and troubleshooting',
                                      onTap: _openSupportWebsite,
                                    ),
                                    const SizedBox(height: 12),
                                    HeavyMetalHubTile(
                                      icon: Icons.language_outlined,
                                      label: 'App Web Page',
                                      subtitle: 'Visit the FactLockCam website',
                                      onTap: () => _showComingSoon('App Web Page'),
                                    ),
                                    const SizedBox(height: 12),
                                    HeavyMetalHubTile(
                                      icon: Icons.menu_book_outlined,
                                      label: 'User Guide',
                                      subtitle: 'Documentation and how-to guides',
                                      onTap: () => _showComingSoon('User Guide'),
                                    ),
                                  ],
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
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: AppTextStyles.monoSm(
        color: AppColors.starkWhite.withValues(alpha: 0.52),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 14),
        color: AppColors.titaniumPanel.withValues(alpha: 0.92),
        disabledColor: AppColors.titaniumPanel.withValues(alpha: 0.5),
        onPressed: onPressed,
        child: Text(
          label.toUpperCase(),
          style: AppTextStyles.monoMd(
            color: onPressed == null
                ? AppColors.starkWhite.withValues(alpha: 0.4)
                : color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
