import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../features/ugc_safety/presentation/widgets/block_sender_dialog.dart';
import '../../features/ugc_safety/presentation/widgets/report_content_sheet.dart';
import 'courier_unlock_notifier.dart';
import 'courier_unlock_phase.dart';
import 'widgets/courier_gate_panel.dart';
import 'widgets/courier_media_stage.dart';
import 'widgets/courier_proof_panel.dart';
import 'widgets/hash_cascade_ticker.dart';
import 'widgets/viral_loop_overlay.dart';

class CourierUnlockView extends ConsumerStatefulWidget {
  const CourierUnlockView({super.key, required this.packageId});

  static const routePath = '/courier';

  final String? packageId;

  @override
  ConsumerState<CourierUnlockView> createState() => _CourierUnlockViewState();
}

class _CourierUnlockViewState extends ConsumerState<CourierUnlockView> {
  final _emailController = TextEditingController();
  final _challengeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(courierUnlockProvider.notifier)
          .loadAttemptStatus(widget.packageId);
    });
  }

  @override
  void didUpdateWidget(covariant CourierUnlockView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.packageId != widget.packageId) {
      ref.read(courierUnlockProvider.notifier).reset();
      ref
          .read(courierUnlockProvider.notifier)
          .loadAttemptStatus(widget.packageId);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _challengeController.dispose();
    super.dispose();
  }

  void _unlock() {
    ref.read(courierUnlockProvider.notifier).unlock(
          widget.packageId,
          _challengeController.text,
          _emailController.text,
        );
  }

  Future<void> _report() async {
    final packageId = widget.packageId;
    if (packageId == null || packageId.isEmpty) return;
    await showReportContentSheet(
      context: context,
      ref: ref,
      packageId: packageId,
      reporterEmail: _emailController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(courierUnlockProvider);

    return Scaffold(
      backgroundColor: AppColors.titaniumDeep,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: SingleChildScrollView(
                key: ValueKey(state.phase),
                padding: const EdgeInsets.all(24),
                child: _buildPhaseBody(state),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseBody(CourierUnlockState state) {
    switch (state.phase) {
      case CourierUnlockPhase.idle:
      case CourierUnlockPhase.processing:
        return CourierGatePanel(
          packageId: widget.packageId,
          attemptStatus: state.attemptStatus,
          message: state.message,
          emailController: _emailController,
          challengeController: _challengeController,
          isProcessing: state.phase == CourierUnlockPhase.processing,
          isLocked: state.isLocked,
          onUnlock: _unlock,
          onReport: _report,
        );
      case CourierUnlockPhase.cascadeAnimation:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.targetAssetHash != null)
              HashCascadeTicker(targetHash: state.targetAssetHash!),
          ],
        );
      case CourierUnlockPhase.playbackReady:
      case CourierUnlockPhase.viralLoop:
        return _PlaybackLayout(
          state: state,
          packageId: widget.packageId,
          reporterEmail: _emailController.text,
        );
    }
  }
}

class _PlaybackLayout extends ConsumerWidget {
  const _PlaybackLayout({
    required this.state,
    required this.packageId,
    required this.reporterEmail,
  });

  final CourierUnlockState state;
  final String? packageId;
  final String reporterEmail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bytes = state.verifiedBytes;
    if (bytes == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            CourierMediaStage(
              bytes: bytes,
              fileExtension: state.fileExtension,
              contentMimeType: state.contentMimeType,
              onPlaybackCompleted: () => ref
                  .read(courierUnlockProvider.notifier)
                  .onPlaybackCompleted(),
            ),
            if (state.phase == CourierUnlockPhase.viralLoop)
              ViralLoopOverlay(
                onDismiss: () =>
                    ref.read(courierUnlockProvider.notifier).dismissViralLoop(),
              ),
          ],
        ),
        const SizedBox(height: 20),
        CourierProofPanel(
          packageId: packageId,
          assetHash: state.targetAssetHash,
          attestation: state.attestation,
          showDeepDive: state.showProofDeepDive,
          onToggleDeepDive: () =>
              ref.read(courierUnlockProvider.notifier).toggleProofDeepDive(),
        ),
        if (packageId != null && packageId!.isNotEmpty) ...[
          const SizedBox(height: 16),
          TextButton(
            onPressed: () async {
              await showReportContentSheet(
                context: context,
                ref: ref,
                packageId: packageId!,
                reporterEmail: reporterEmail,
              );
              if (!context.mounted) return;
              await showBlockSenderDialog(
                context: context,
                ref: ref,
                packageId: packageId!,
                reporterEmail: reporterEmail,
              );
            },
            child: Text(
              'Report & block sender',
              style: AppTextStyles.monoSm(color: AppColors.alertAmber),
            ),
          ),
        ],
      ],
    );
  }
}
