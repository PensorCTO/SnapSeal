import 'package:flutter_test/flutter_test.dart';
import 'package:postgrest/postgrest.dart';

import 'package:factlockcam/features/archive_quota/data/archive_quota_rpc.dart';

void main() {
  /// Shape returned by `get_my_archive_quota` jsonb_build_object in migration.
  final fixture = <String, dynamic>{
    'user_id': '550e8400-e29b-41d4-a716-446655440000',
    'tier_id': 'free',
    'display_name': 'Zero-Trust Tourist',
    'storage_used_bytes': 1024,
    'storage_limit_bytes': 52428800,
    'egress_used_bytes': '2048',
    'egress_limit_bytes': 3221225472,
    'egress_period_start': '2026-06-01T00:00:00.000Z',
    'monthly_price_cents': 0,
    'updated_at': '2026-06-02T12:00:00.000Z',
    'storage_pct': 0.0,
    'egress_pct': 0.0,
  };

  group('parseGetMyArchiveQuotaResponse', () {
    test('parses Map payload', () {
      final map = parseGetMyArchiveQuotaResponse(fixture);
      expect(map['tier_id'], 'free');
      expect(map['storage_used_bytes'], 1024);
    });

    test('parses JSON string payload', () {
      const encoded =
          '{"tier_id":"picture","display_name":"The Creator",'
          '"storage_used_bytes":100,"storage_limit_bytes":5368709120,'
          '"egress_used_bytes":0,"egress_limit_bytes":26843545600,'
          '"monthly_price_cents":100}';
      final map = parseGetMyArchiveQuotaResponse(encoded);
      expect(map['tier_id'], 'picture');
    });

    test('rejects null', () {
      expect(
        () => parseGetMyArchiveQuotaResponse(null),
        throwsFormatException,
      );
    });
  });

  group('snapshotFromGetMyArchiveQuotaResponse', () {
    test('builds snapshot with string bigint fields', () {
      final snapshot = snapshotFromGetMyArchiveQuotaResponse(fixture);
      expect(snapshot.tier.tierId, 'free');
      expect(snapshot.tier.displayName, 'Zero-Trust Tourist');
      expect(snapshot.storageUsedBytes, 1024);
      expect(snapshot.egressUsedBytes, 2048);
      expect(snapshot.egressPeriodStart, isNotNull);
    });
  });

  group('describeArchiveQuotaRpcError', () {
    test('includes PGRST202 hint', () {
      final message = describeArchiveQuotaRpcError(
        const PostgrestException(
          message: 'Could not find the function',
          code: 'PGRST202',
        ),
      );
      expect(message, contains('PGRST202'));
      expect(message, contains('migration push'));
    });

    test('uses custom rpc name', () {
      final message = describeArchiveQuotaRpcError(
        StateError('fail'),
        rpcName: 'get_current_quota_status',
      );
      expect(message, contains('get_current_quota_status'));
    });
  });
}
