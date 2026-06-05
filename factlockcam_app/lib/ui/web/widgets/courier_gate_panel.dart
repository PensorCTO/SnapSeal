import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/marketing/approved_pitch.dart';

class CourierGatePanel extends StatefulWidget {
  const CourierGatePanel({
    super.key,
    required this.packageId,
    required this.attemptStatus,
    required this.message,
    required this.emailController,
    required this.challengeController,
    required this.isProcessing,
    required this.isLocked,
    required this.onUnlock,
    required this.onReport,
    this.showReport = true,
  });

  final String? packageId;
  final Map<String, dynamic>? attemptStatus;
  final String? message;
  final TextEditingController emailController;
  final TextEditingController challengeController;
  final bool isProcessing;
  final bool isLocked;
  final VoidCallback onUnlock;
  final VoidCallback onReport;
  final bool showReport;

  @override
  State<CourierGatePanel> createState() => _CourierGatePanelState();
}

class _CourierGatePanelState extends State<CourierGatePanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inputsEnabled = !widget.isProcessing && !widget.isLocked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          courierConsoleHeadline,
          style: AppTextStyles.monoLg(color: AppColors.verifiedNeon),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          courierConsoleGateSubtitle,
          style: AppTextStyles.monoSm(
            color: AppColors.starkWhite.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        RepaintBoundary(
          child: _StatusPanel(
            packageId: widget.packageId,
            attemptStatus: widget.attemptStatus,
            message: widget.message,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: widget.emailController,
          enabled: inputsEnabled,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          style: AppTextStyles.monoSm(),
          decoration: InputDecoration(
            labelText: 'Recipient email',
            hintText: 'name@example.com',
            filled: true,
            fillColor: AppColors.titaniumPanel,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.titaniumEdge),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.titaniumEdge),
            ),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final alpha = 0.25 + (_pulseController.value * 0.35);
            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.kineticGreen.withValues(alpha: alpha),
                  width: 1,
                ),
              ),
              child: child,
            );
          },
          child: TextField(
            controller: widget.challengeController,
            enabled: inputsEnabled,
            obscureText: true,
            style: AppTextStyles.monoSm(),
            decoration: InputDecoration(
              labelText: 'One-time password',
              filled: true,
              fillColor: AppColors.titaniumPanel,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (_) => widget.onUnlock(),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: inputsEnabled ? widget.onUnlock : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.kineticGreen,
            foregroundColor: AppColors.titaniumDeep,
            minimumSize: const Size.fromHeight(44),
          ),
          child: widget.isProcessing
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  'Unlock Archive package',
                  style: AppTextStyles.monoSm(fontWeight: FontWeight.w700),
                ),
        ),
        if (widget.showReport &&
            widget.packageId != null &&
            widget.packageId!.isNotEmpty) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: widget.isProcessing ? null : widget.onReport,
            child: Text(
              'Report concerning content',
              style: AppTextStyles.monoSm(color: AppColors.alertAmber),
            ),
          ),
        ],
      ],
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
