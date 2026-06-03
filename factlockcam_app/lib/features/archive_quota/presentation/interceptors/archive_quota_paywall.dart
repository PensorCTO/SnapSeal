import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/archive_quota_snapshot.dart';
import '../providers/archive_quota_provider.dart';
import '../views/subscription_upgrade_view.dart';
import 'archive_quota_block_reason.dart';

/// Presents the Archive subscription paywall when quota gates block an action.
Future<void> presentArchiveQuotaPaywall(
  BuildContext context,
  WidgetRef ref, {
  required ArchiveQuotaBlockReason reason,
}) {
  return showCupertinoModalPopup<void>(
    context: context,
    builder: (context) => SubscriptionUpgradeView(blockReason: reason),
  );
}

/// Returns false when the action should be blocked and the paywall was shown.
Future<bool> ensureArchiveQuotaForSeal(
  BuildContext context,
  WidgetRef ref, {
  required int incomingBytes,
}) async {
  final snapshot = await _resolveSnapshot(ref);
  if (snapshot == null) return true;

  final service = ref.read(archiveQuotaServiceProvider);
  if (service.canSeal(snapshot, incomingBytes: incomingBytes)) {
    return true;
  }

  if (!context.mounted) return false;
  await presentArchiveQuotaPaywall(
    context,
    ref,
    reason: ArchiveQuotaBlockReason.storage,
  );
  return false;
}

/// Returns false when Send Proof should be blocked and the paywall was shown.
Future<bool> ensureArchiveQuotaForSendProof(
  BuildContext context,
  WidgetRef ref,
) async {
  final snapshot = await _resolveSnapshot(ref);
  if (snapshot == null) return true;

  final service = ref.read(archiveQuotaServiceProvider);
  if (service.canSendProof(snapshot)) {
    return true;
  }

  if (!context.mounted) return false;
  await presentArchiveQuotaPaywall(
    context,
    ref,
    reason: ArchiveQuotaBlockReason.egress,
  );
  return false;
}

Future<ArchiveQuotaSnapshot?> _resolveSnapshot(WidgetRef ref) async {
  final cached = ref.read(archiveQuotaNotifierProvider).value;
  if (cached != null) return cached;

  final service = ref.read(archiveQuotaServiceProvider);
  if (!service.isConfigured) return null;

  try {
    return await service.refresh();
  } catch (_) {
    return null;
  }
}
