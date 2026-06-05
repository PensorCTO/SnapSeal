import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../features/ugc_safety/presentation/widgets/block_sender_dialog.dart';
import '../../features/ugc_safety/presentation/widgets/report_content_sheet.dart';
import 'courier_unlock_notifier.dart';

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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(courierUnlockProvider);

    return Scaffold(
      backgroundColor: AppColors.titaniumDeep,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'FactLockCam Courier',
                    style: AppTextStyles.monoLg(color: AppColors.verifiedNeon),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unlock and verify an encrypted courier package locally in this browser.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _StatusPanel(
                    packageId: widget.packageId,
                    attemptStatus: state.attemptStatus,
                    message: state.message,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    enabled: !state.isLoading && !state.isLocked,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Recipient email',
                      hintText: 'name@example.com',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _challengeController,
                    enabled: !state.isLoading && !state.isLocked,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'One-time password',
                    ),
                    onSubmitted: (_) => _unlock(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed:
                        state.isLoading || state.isLocked ? null : _unlock,
                    child: state.isLoading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Unlock package'),
                  ),
                  if (widget.packageId != null &&
                      widget.packageId!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: state.isLoading
                          ? null
                          : () => showReportContentSheet(
                                context: context,
                                ref: ref,
                                packageId: widget.packageId!,
                                reporterEmail: _emailController.text,
                              ),
                      child: Text(
                        'Report concerning content',
                        style: AppTextStyles.monoSm(
                          color: AppColors.alertAmber,
                        ),
                      ),
                    ),
                  ],
                  if (state.verifiedBytes != null) ...[
                    const SizedBox(height: 24),
                    _VerifiedPreview(
                      bytes: state.verifiedBytes!,
                      fileExtension: state.fileExtension,
                      packageId: widget.packageId,
                      reporterEmail: _emailController.text,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.packageId,
    required this.attemptStatus,
    required this.message,
  });

  final String? packageId;
  final Map<String, dynamic>? attemptStatus;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final attemptsRemaining = attemptStatus?['attempts_remaining'];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.titaniumPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.titaniumEdge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DefaultTextStyle(
          style: AppTextStyles.monoSm(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PACKAGE: ${packageId ?? 'missing'}'),
              if (attemptStatus != null) ...[
                const SizedBox(height: 8),
                Text('STATUS: ${attemptStatus!['status']}'),
                Text('ATTEMPTS REMAINING: $attemptsRemaining'),
              ],
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  style: AppTextStyles.monoSm(color: AppColors.alertAmber),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _VerifiedPreview extends ConsumerWidget {
  const _VerifiedPreview({
    required this.bytes,
    required this.fileExtension,
    required this.packageId,
    required this.reporterEmail,
  });

  final Uint8List bytes;
  final String? fileExtension;
  final String? packageId;
  final String reporterEmail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = (fileExtension ?? '').replaceFirst('.', '');
    final isImage = {'jpg', 'jpeg', 'png', 'gif', 'webp'}.contains(ext);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.verifiedNeon.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isImage)
              Image.memory(bytes, fit: BoxFit.contain)
            else
              Text(
                'Verified ${ext.isEmpty ? 'asset' : '.$ext asset'} (${bytes.length} bytes). Preview support for this type is not enabled yet.',
                style: AppTextStyles.monoMd(),
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
        ),
      ),
    );
  }
}
