import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

class CourierProofPanel extends StatelessWidget {
  const CourierProofPanel({
    super.key,
    required this.packageId,
    required this.assetHash,
    required this.attestation,
    required this.showDeepDive,
    required this.onToggleDeepDive,
  });

  final String? packageId;
  final String? assetHash;
  final Map<String, dynamic>? attestation;
  final bool showDeepDive;
  final VoidCallback onToggleDeepDive;

  @override
  Widget build(BuildContext context) {
    final found = attestation?['found'] == true;
    final txHash = attestation?['chain_tx_hash'] as String?;
    final sealedAt = attestation?['sealed_at'] as String?;
    final blockNumber = attestation?['block_number'];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.titaniumPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.titaniumEdge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'PROOF PANEL',
              style: AppTextStyles.monoSm(
                color: AppColors.verifiedNeon,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _ProofRow(label: 'PACKAGE', value: packageId ?? 'missing'),
            const SizedBox(height: 8),
            _ProofRow(
              label: 'ASSET HASH',
              value: assetHash ?? '—',
              valueColor: AppColors.verifiedNeon,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onToggleDeepDive,
              child: Text(
                showDeepDive ? 'Hide details' : 'Proof details',
                style: AppTextStyles.monoSm(color: AppColors.kineticGreen),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState: showDeepDive
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 4),
                  _ProofRow(
                    label: 'TRANSACTION ID',
                    value: found && txHash != null && txHash.isNotEmpty
                        ? txHash
                        : 'Ledger attestation pending',
                  ),
                  const SizedBox(height: 8),
                  _ProofRow(
                    label: 'SEALED AT',
                    value: found && sealedAt != null && sealedAt.isNotEmpty
                        ? sealedAt
                        : 'Unavailable',
                  ),
                  const SizedBox(height: 8),
                  _ProofRow(
                    label: 'BLOCK INDEX',
                    value: blockNumber != null
                        ? blockNumber.toString()
                        : 'Unavailable',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProofRow extends StatelessWidget {
  const _ProofRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.monoSm()),
        const SizedBox(height: 4),
        SelectableText(
          value,
          style: AppTextStyles.monoSm(
            color: valueColor ?? AppColors.starkWhite.withValues(alpha: 0.88),
          ),
        ),
      ],
    );
  }
}
