import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_repository.dart';

final sealLedgerRepositoryProvider = Provider<SealLedgerRepository>(
  (ref) => SealLedgerRepository(ref.watch(supabaseClientProvider)),
);

enum SealLedgerSyncStatus { synced, alreadySynced }

class SealLedgerRepository {
  const SealLedgerRepository(this._client);

  final SupabaseClient? _client;

  bool get isConfigured => _client != null;

  Future<SealLedgerSyncStatus> syncAssetFingerprint(
    String assetFingerprint,
  ) async {
    final client = _requiredClient();
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No authenticated user for seal ledger sync.');
    }

    final walletId = await _getWalletId(client, userId);
    try {
      await client.from('seal_ledger').insert({
        'asset_fingerprint': assetFingerprint,
        'wallet_id': walletId,
      });
      return SealLedgerSyncStatus.synced;
    } on PostgrestException catch (error) {
      if (error.code != '23505') {
        rethrow;
      }

      final existing = await client
          .from('seal_ledger')
          .select('wallet_id')
          .eq('asset_fingerprint', assetFingerprint)
          .maybeSingle();
      if (existing != null && existing['wallet_id'] == walletId) {
        return SealLedgerSyncStatus.alreadySynced;
      }

      rethrow;
    }
  }

  SupabaseClient _requiredClient() {
    final client = _client;
    if (client == null) {
      throw StateError(
        'Supabase is not configured. Run with --dart-define SUPABASE_URL=... '
        'and --dart-define SUPABASE_ANON_KEY=...',
      );
    }
    return client;
  }

  Future<String> _getWalletId(SupabaseClient client, String userId) async {
    final row = await client
        .from('profiles')
        .select('wallet_id')
        .eq('id', userId)
        .single();
    final walletId = row['wallet_id'] as String?;
    if (walletId == null || walletId.isEmpty) {
      throw StateError('No wallet_id found for current user.');
    }
    return walletId;
  }
}
