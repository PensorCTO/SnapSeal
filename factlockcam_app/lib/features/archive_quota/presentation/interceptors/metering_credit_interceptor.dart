import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/metered_action_type.dart';
import '../../domain/models/quota_state.dart';
import '../providers/quota_state_provider.dart';
import '../views/subscription_upgrade_view.dart';
import 'archive_quota_block_reason.dart';

/// Pre-flight modal before heavy verification / export actions.
Future<bool> ensureVerificationCreditForAction(
  BuildContext context,
  WidgetRef ref,
) async {
  final quota = await _resolveQuotaState(ref);
  if (quota == null) {
    return true;
  }

  if (quota.hasVerificationCredits) {
    if (!context.mounted) {
      return false;
    }
    return _showVerificationCreditDialog(context, quota);
  }

  if (!context.mounted) {
    return false;
  }
  await showCupertinoModalPopup<void>(
    context: context,
    builder: (context) => const SubscriptionUpgradeView(
      blockReason: ArchiveQuotaBlockReason.egress,
    ),
  );
  return false;
}

Future<bool> _showVerificationCreditDialog(
  BuildContext context,
  QuotaState quota,
) {
  return showCupertinoDialog<bool>(
    context: context,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: const Text('Verification Credit'),
      content: Text(
        'This action requires 1 Verification Credit. '
        'Balance: ${quota.egressCreditsBalance}.',
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Proceed'),
        ),
      ],
    ),
  ).then((value) => value ?? false);
}

Future<QuotaState?> _resolveQuotaState(WidgetRef ref) async {
  final cached = ref.read(quotaStateProvider);
  if (cached != null) {
    return cached;
  }

  final service = ref.read(meteringQuotaServiceProvider);
  if (!service.isConfigured) {
    return null;
  }

  await ref.read(quotaStateProvider.notifier).refresh();
  return ref.read(quotaStateProvider);
}

/// Runs [action] after optimistic debit, recording consumption on success.
Future<void> runMeteredVerificationAction(
  WidgetRef ref,
  Future<void> Function() action,
) async {
  ref.read(quotaStateProvider.notifier).optimisticDebit(
        MeteredActionType.verificationCredit,
      );
  try {
    await action();
    unawaited(
      ref
          .read(quotaStateProvider.notifier)
          .recordAndReconcile(MeteredActionType.verificationCredit),
    );
  } catch (error) {
    ref.read(quotaStateProvider.notifier).rollbackOptimistic();
    rethrow;
  }
}

/// Records a pro-proof debit after a successful seal.
Future<void> recordProProofConsumption(WidgetRef ref) async {
  ref.read(quotaStateProvider.notifier).optimisticDebit(
        MeteredActionType.proProof,
      );
  unawaited(
    ref.read(quotaStateProvider.notifier).recordAndReconcile(
          MeteredActionType.proProof,
        ),
  );
}
