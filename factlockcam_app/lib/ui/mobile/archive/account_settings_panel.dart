import 'package:factlockcam/app/theme/app_colors.dart';
import 'package:factlockcam/app/theme/app_typography.dart';
import 'package:factlockcam/core/config/app_config.dart';
import 'package:factlockcam/core/di/service_providers.dart';
import 'package:factlockcam/core/legal/disclaimers.dart';
import 'package:factlockcam/core/navigation/compliance_navigation.dart';
import 'package:factlockcam/core/ui/widgets/archive_panel_navigation_bar.dart';
import 'package:factlockcam/core/ui/widgets/heavy_metal_backdrop.dart';
import 'package:factlockcam/core/ui/widgets/heavy_metal_hub_tile.dart';
import 'package:factlockcam/features/archive_quota/presentation/widgets/quota_telemetry_widget.dart';
import 'package:factlockcam/ui/mobile/settings/burn_account_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show Icons, Scaffold;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

/// Account & Settings panel — logout, key custody, account deletion, legal links.
class AccountSettingsPanel extends ConsumerStatefulWidget {
  const AccountSettingsPanel({super.key, this.onBackToHub});

  final VoidCallback? onBackToHub;

  @override
  ConsumerState<AccountSettingsPanel> createState() =>
      _AccountSettingsPanelState();
}

class _AccountSettingsPanelState extends ConsumerState<AccountSettingsPanel>
    with HeavyMetalBackdropMixin<AccountSettingsPanel> {
  bool _busy = false;

  bool get _keyCustodyEnabled => !kIsWeb && AppConfig.usePolygonNotarizer;

  Future<void> _openCompliancePage(String url) async {
    try {
      await ComplianceNavigation.openCompliancePage(url);
    } catch (error) {
      if (!mounted) return;
      await _showAlert('Unable to open link', error.toString());
    }
  }

  Future<void> _openSupportWebsite() =>
      _openCompliancePage(AppConfig.supportUrl);

  Future<void> _signOut() async {
    await ref.read(authControllerProvider.notifier).signOut();
    ref
      ..invalidate(dashboardControllerProvider)
      ..invalidate(thumbnailCacheProvider);
  }

  Future<void> _exportArchiveKeys() async {
    final passwords = await _promptBackupPasswords();
    if (passwords == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final file = await ref.read(walletBackupServiceProvider).exportFactlock(
        backupPassword: passwords.$1,
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              file.path,
              mimeType: 'application/octet-stream',
              name: 'factlockcam-archive-keys.factlock',
            ),
          ],
          subject: 'FactLockCam Archive Key Backup',
        ),
      );
    } catch (error) {
      if (!mounted) return;
      await _showAlert('Export failed', error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<(String, String)?> _promptBackupPasswords() async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    String? errorText;
    String? capturedPassword;

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return CupertinoAlertDialog(
              title: const Text('Export Archive Keys'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  const Text(exportArchiveKeysDisclaimer),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: passwordController,
                    obscureText: true,
                    placeholder: 'Backup password',
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: confirmController,
                    obscureText: true,
                    placeholder: 'Confirm password',
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorText!,
                      style: const TextStyle(
                        color: CupertinoColors.destructiveRed,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () {
                    final password = passwordController.text;
                    final confirm = confirmController.text;
                    if (password.length < 8) {
                      setDialogState(() {
                        errorText = 'Password must be at least 8 characters.';
                      });
                      return;
                    }
                    if (password != confirm) {
                      setDialogState(() {
                        errorText = 'Passwords do not match.';
                      });
                      return;
                    }
                    capturedPassword = password;
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: const Text('Export'),
                ),
              ],
            );
          },
        );
      },
    );

    passwordController.dispose();
    confirmController.dispose();

    if (confirmed != true || capturedPassword == null) return null;
    return (capturedPassword!, capturedPassword!);
  }

  Future<void> _lockArchive() async {
    final hasBackup =
        await ref.read(backupMetadataStoreProvider).hasCompletedBackup();
    if (!hasBackup) {
      await _showAlert(
        'Backup required',
        'Export Archive Keys at least once before locking the archive.',
      );
      return;
    }

    if (!mounted) return;

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Lock Archive?'),
        content: const Text(lockArchiveDisclaimer),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Lock Archive'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(appLockCoordinatorProvider).lockArchive();
      await ref.read(keyCustodyProvider.notifier).refresh();
    } catch (error) {
      if (!mounted) return;
      await _showAlert('Lock failed', error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _openBurnAccount() {
    context.push(BurnAccountView.routePath);
  }

  Future<void> _showKeyCustodyLimits() {
    return showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Key custody & limits'),
        content: SingleChildScrollView(
          child: Text(
            accountKeyCustodyBlock,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAlert(String title, String message) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final busy = _busy || auth.isLoading;

    return Scaffold(
      backgroundColor: AppColors.titaniumDeep,
      body: Column(
        children: [
          if (widget.onBackToHub != null)
            ArchivePanelNavigationBar(
              title: 'Account',
              onBack: widget.onBackToHub!,
            ),
          HeavyMetalLogoBanner(
            includeTopSafeArea: widget.onBackToHub == null,
          ),
          const QuotaTelemetryWidget(),
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
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  16,
                                  20,
                                  16,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
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
                                    _SectionLabel('LEGAL & SUPPORT'),
                                    const SizedBox(height: 12),
                                    HeavyMetalHubTile(
                                      icon: Icons.description_outlined,
                                      label: 'Terms of Service',
                                      subtitle:
                                          'End-user license and usage terms',
                                      onTap: () => _openCompliancePage(
                                        AppConfig.termsUrl,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    HeavyMetalHubTile(
                                      icon: Icons.shield_outlined,
                                      label: 'Privacy Policy',
                                      subtitle:
                                          'How we handle your data on this device',
                                      onTap: () => _openCompliancePage(
                                        AppConfig.privacyUrl,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    HeavyMetalHubTile(
                                      icon: Icons.help_outline,
                                      label: 'Help & Support',
                                      subtitle:
                                          'Contact support and troubleshooting',
                                      onTap: _openSupportWebsite,
                                    ),
                                    const SizedBox(height: 12),
                                    HeavyMetalHubTile(
                                      icon: Icons.language_outlined,
                                      label: 'App Web Page',
                                      subtitle: 'Visit the FactLockCam website',
                                      onTap: () => _openCompliancePage(
                                        AppConfig.webBaseUrl,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    HeavyMetalHubTile(
                                      icon: Icons.menu_book_outlined,
                                      label: 'User Guide',
                                      subtitle:
                                          'Documentation and how-to guides',
                                      onTap: () => _openCompliancePage(
                                        AppConfig.guideUrl,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    HeavyMetalHubTile(
                                      icon: Icons.vpn_key_outlined,
                                      label: 'Key custody & limits',
                                      subtitle:
                                          'Zero-knowledge keys, file integrity, Polygon',
                                      onTap: _showKeyCustodyLimits,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                8,
                                20,
                                24,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _ActionButton(
                                    label: 'Log out',
                                    color: AppColors.kineticGreen,
                                    onPressed: busy ? null : _signOut,
                                  ),
                                  if (_keyCustodyEnabled) ...[
                                    const SizedBox(height: 12),
                                    _ActionButton(
                                      label: 'Export archive keys',
                                      color: AppColors.kineticGreen,
                                      onPressed:
                                          busy ? null : _exportArchiveKeys,
                                    ),
                                    const SizedBox(height: 12),
                                    _ActionButton(
                                      label: 'Lock archive',
                                      color: CupertinoColors.systemOrange,
                                      onPressed: busy ? null : _lockArchive,
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  _ActionButton(
                                    label: 'Burn account',
                                    color: CupertinoColors.destructiveRed,
                                    onPressed: busy ? null : _openBurnAccount,
                                  ),
                                ],
                              ),
                            ),
                          ],
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
