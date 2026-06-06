import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/di/service_providers.dart';
import '../../core/marketing/approved_pitch.dart';
import '../../core/ui/widgets/archive_panel_navigation_bar.dart';
import '../../data/models/archive_item.dart';
import '../../features/archive/presentation/providers/send_proof_provider.dart';
import '../../features/archive_quota/presentation/interceptors/archive_quota_paywall.dart';
import '../../features/dispatch/presentation/archive_dispatch_preset_control.dart';
import '../../features/dispatch/presentation/dispatch_console_state.dart';
import '../../features/dispatch/presentation/dispatch_error_copy.dart';
import 'archive_thumbnail.dart';

enum _SecureCommStep { selectAsset, configureAndSend }

/// Mobile Secure Comm flow — select archive asset, then configure policy and
/// transmit via the full Send Proof path (certificate PDF + share sheet).
class CourierDispatchView extends ConsumerStatefulWidget {
  const CourierDispatchView({super.key, required this.onBackToHub});

  final VoidCallback onBackToHub;

  @override
  ConsumerState<CourierDispatchView> createState() => _CourierDispatchViewState();
}

class _CourierDispatchViewState extends ConsumerState<CourierDispatchView> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _passwordEmpty = true;
  _SecureCommStep _step = _SecureCommStep.selectAsset;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    final empty = _passwordController.text.trim().isEmpty;
    if (empty != _passwordEmpty) {
      setState(() => _passwordEmpty = empty);
    }
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _passwordController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (_step == _SecureCommStep.configureAndSend) {
      setState(() => _step = _SecureCommStep.selectAsset);
      return;
    }
    widget.onBackToHub();
  }

  void _continueToConfigure() {
    final dispatch = ref.read(dispatchConsoleProvider);
    if (dispatch.selectedAssetHash == null) {
      return;
    }
    setState(() => _step = _SecureCommStep.configureAndSend);
  }

  bool _canTransmit(DispatchConsoleState dispatch) {
    return dispatch.selectedAssetHash != null && !_passwordEmpty;
  }

  ArchiveItem? _resolveSelectedItem(List<ArchiveItem> items, String? hash) {
    if (hash == null) return null;
    for (final item in items) {
      if (item.assetFingerprint == hash) {
        return item;
      }
    }
    return null;
  }

  Future<void> _transmitProof() async {
    final dispatch = ref.read(dispatchConsoleProvider);
    final items = ref.read(dashboardControllerProvider).value ?? const [];
    final selected = _resolveSelectedItem(items, dispatch.selectedAssetHash);
    final password = _passwordController.text.trim();

    if (selected == null) {
      await _showAlert('Select a sealed archive item to transmit.');
      return;
    }
    if (password.isEmpty) {
      await _showAlert('Recipient password is required.');
      return;
    }

    if (!mounted) return;
    if (!await ensureArchiveQuotaForSendProof(context, ref)) {
      return;
    }

    if (!mounted) return;
    unawaited(_showLoadingDialog());

    try {
      final result = await ref.read(sendProofProvider.notifier).send(
            SendProofRequest(
              item: selected,
              password: password,
              maxDownloads: dispatch.maxDownloads,
              linkTtlDays: dispatch.linkTtlDays,
            ),
          );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              result.certificatePdfPath,
              mimeType: 'application/pdf',
              name: 'factlockcam-certificate.pdf',
            ),
          ],
          text:
              '$sendProofShareIntro${result.courierUrl}\n\n'
              'Share the password separately.\n\n'
              'Attached: tamper-proof certificate with asset hash and ledger details.',
        ),
      );
    } catch (error) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await _showTransmitError(friendlyCourierDispatchError(error));
    }
  }

  Future<void> _showAlert(String message) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(message),
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

  Future<void> _showTransmitError(String message) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Could not transmit proof'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showLoadingDialog() {
    return showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CupertinoAlertDialog(
        content: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CupertinoActivityIndicator(radius: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(dashboardControllerProvider);
    final dispatch = ref.watch(dispatchConsoleProvider);
    final items = itemsAsync.value ?? const <ArchiveItem>[];

    return ColoredBox(
      color: AppColors.titaniumDeep,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ArchivePanelNavigationBar(
            title: 'SECURE COMM',
            heroTag: 'secure_comm_nav',
            onBack: _handleBack,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: _step == _SecureCommStep.selectAsset
                  ? _buildSelectAssetStep(items, dispatch)
                  : _buildConfigureAndSendStep(dispatch),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectAssetStep(
    List<ArchiveItem> items,
    DispatchConsoleState dispatch,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          mechanismTagline,
          style: AppTextStyles.monoSm(
            color: AppColors.starkWhite.withValues(alpha: 0.72),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'SELECT ARCHIVE ITEM',
          style: AppTextStyles.monoSm(
            color: AppColors.starkWhite.withValues(alpha: 0.55),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          _EmptyArchiveStaging()
        else
          RepaintBoundary(
            child: _DispatchStagingGrid(
              items: items,
              selectedHash: dispatch.selectedAssetHash,
              onSelect: (hash) => ref
                  .read(dispatchConsoleProvider.notifier)
                  .selectAsset(hash),
            ),
          ),
        const SizedBox(height: 28),
        CupertinoButton.filled(
          onPressed: dispatch.selectedAssetHash != null
              ? _continueToConfigure
              : null,
          color: AppColors.kineticGreen,
          disabledColor: AppColors.titaniumPanel,
          borderRadius: BorderRadius.zero,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'CONTINUE',
            style: AppTextStyles.monoSm(
              color: AppColors.titaniumDeep,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfigureAndSendStep(DispatchConsoleState dispatch) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Configure delivery policy and recipient password, then transmit.',
          style: AppTextStyles.monoSm(
            color: AppColors.starkWhite.withValues(alpha: 0.72),
          ),
        ),
        const SizedBox(height: 24),
        _DispatchParametersPanel(
          maxDownloads: dispatch.maxDownloads,
          linkTtlDays: dispatch.linkTtlDays,
          onMaxDownloadsChanged: ref
              .read(dispatchConsoleProvider.notifier)
              .setMaxDownloads,
          onLinkTtlChanged: ref
              .read(dispatchConsoleProvider.notifier)
              .setLinkTtlDays,
        ),
        const SizedBox(height: 24),
        Text(
          'RECIPIENT PASSWORD',
          style: AppTextStyles.monoSm(
            color: AppColors.starkWhite.withValues(alpha: 0.55),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          placeholder: 'Verifier password for recipient',
          style: AppTextStyles.monoSm(color: AppColors.starkWhite),
          placeholderStyle: AppTextStyles.monoSm(
            color: AppColors.starkWhite.withValues(alpha: 0.35),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.titaniumPanel,
            border: Border.all(
              color: AppColors.titaniumEdge.withValues(alpha: 0.8),
            ),
          ),
          suffix: CupertinoButton(
            padding: const EdgeInsets.only(right: 8),
            minimumSize: Size.zero,
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            child: Icon(
              _obscurePassword
                  ? CupertinoIcons.eye_slash
                  : CupertinoIcons.eye,
              size: 18,
              color: AppColors.starkWhite.withValues(alpha: 0.55),
            ),
          ),
        ),
        const SizedBox(height: 28),
        CupertinoButton.filled(
          onPressed: _canTransmit(dispatch) ? _transmitProof : null,
          color: AppColors.kineticGreen,
          disabledColor: AppColors.titaniumPanel,
          borderRadius: BorderRadius.zero,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'TRANSMIT PROOF',
            style: AppTextStyles.monoSm(
              color: AppColors.titaniumDeep,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyArchiveStaging extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.titaniumPanel,
        border: Border.all(
          color: AppColors.titaniumEdge.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No sealed assets in archive. Seal media from Picture or Video first.',
          style: AppTextStyles.monoSm(
            color: AppColors.starkWhite.withValues(alpha: 0.42),
          ),
        ),
      ),
    );
  }
}

class _DispatchStagingGrid extends StatelessWidget {
  const _DispatchStagingGrid({
    required this.items,
    required this.selectedHash,
    required this.onSelect,
  });

  final List<ArchiveItem> items;
  final String? selectedHash;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = item.assetFingerprint == selectedHash;
          final isVideo = item.mimeType?.startsWith('video/') ?? false;
          final shortHash = item.assetFingerprint.length > 8
              ? item.assetFingerprint.substring(0, 8).toUpperCase()
              : item.assetFingerprint.toUpperCase();

          return GestureDetector(
            onTap: () => onSelect(item.assetFingerprint),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 108,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? AppColors.kineticGreen
                      : AppColors.titaniumEdge.withValues(alpha: 0.6),
                  width: isSelected ? 2 : 1,
                ),
                color: AppColors.titaniumPanel,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ArchiveThumbnail(
                      thumbnailPath: item.thumbnailPath,
                      showVideoBadge: isVideo,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Text(
                      shortHash,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.monoSm(
                        color: isSelected
                            ? AppColors.kineticGreen
                            : AppColors.starkWhite.withValues(alpha: 0.72),
                      ).copyWith(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DispatchParametersPanel extends StatelessWidget {
  const _DispatchParametersPanel({
    required this.maxDownloads,
    required this.linkTtlDays,
    required this.onMaxDownloadsChanged,
    required this.onLinkTtlChanged,
  });

  final int maxDownloads;
  final int linkTtlDays;
  final ValueChanged<int> onMaxDownloadsChanged;
  final ValueChanged<int> onLinkTtlChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.titaniumPanel,
        border: Border.all(
          color: AppColors.titaniumEdge.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'DISPATCH PARAMETERS',
              style: AppTextStyles.monoSm(
                color: AppColors.starkWhite.withValues(alpha: 0.55),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Max downloads',
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
            const SizedBox(height: 16),
            Text(
              'Link window',
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
          ],
        ),
      ),
    );
  }
}
