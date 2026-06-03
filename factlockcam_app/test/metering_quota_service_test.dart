import 'package:flutter_test/flutter_test.dart';

import 'package:factlockcam/features/archive_quota/data/archive_quota_rpc.dart';
import 'package:factlockcam/features/archive_quota/domain/models/metered_action_type.dart';
import 'package:factlockcam/features/archive_quota/domain/models/quota_state.dart';
import 'package:factlockcam/features/archive_quota/domain/repositories/i_metering_quota_repository.dart';
import 'package:factlockcam/features/archive_quota/domain/services/metering_quota_service.dart';

void main() {
  const statusFixture = <String, dynamic>{
    'pro_proofs_remaining': 34,
    'pro_proofs_base': 50,
    'egress_credits_balance': 12,
    'cycle_end': '2026-07-01T00:00:00.000Z',
  };

  group('parseGetCurrentQuotaStatusResponse', () {
    test('parses Map payload', () {
      final map = parseGetCurrentQuotaStatusResponse(statusFixture);
      expect(map['pro_proofs_remaining'], 34);
      expect(map['egress_credits_balance'], 12);
    });

    test('rejects null', () {
      expect(
        () => parseGetCurrentQuotaStatusResponse(null),
        throwsFormatException,
      );
    });
  });

  group('quotaStateFromGetCurrentQuotaStatusResponse', () {
    test('builds QuotaState', () {
      final state = quotaStateFromGetCurrentQuotaStatusResponse(statusFixture);
      expect(state.proProofsRemaining, 34);
      expect(state.proProofsBase, 50);
      expect(state.egressCreditsBalance, 12);
      expect(state.cycleEnd, isNotNull);
    });
  });

  group('MeteringQuotaService', () {
    late MeteringQuotaService service;

    setUp(() {
      service = MeteringQuotaService(repository: _NoopMeteringQuotaRepository());
    });

    test('optimisticDebit decrements pro proofs', () {
      const current = QuotaState(
        proProofsRemaining: 5,
        proProofsBase: 50,
        egressCreditsBalance: 12,
      );
      final next = service.optimisticDebit(current, MeteredActionType.proProof);
      expect(next.proProofsRemaining, 4);
      expect(next.egressCreditsBalance, 12);
    });

    test('optimisticDebit decrements verification credits', () {
      const current = QuotaState(
        proProofsRemaining: 5,
        proProofsBase: 50,
        egressCreditsBalance: 3,
      );
      final next = service.optimisticDebit(
        current,
        MeteredActionType.verificationCredit,
      );
      expect(next.egressCreditsBalance, 2);
      expect(next.proProofsRemaining, 5);
    });

    test('canDebit respects zero balances', () {
      const empty = QuotaState(
        proProofsRemaining: 0,
        proProofsBase: 50,
        egressCreditsBalance: 0,
      );
      expect(service.canDebit(empty, MeteredActionType.proProof), isFalse);
      expect(
        service.canDebit(empty, MeteredActionType.verificationCredit),
        isFalse,
      );
    });
  });
}

class _NoopMeteringQuotaRepository implements IMeteringQuotaRepository {
  @override
  bool get isConfigured => false;

  @override
  Future<QuotaState> fetchCurrentQuotaStatus() => throw UnimplementedError();

  @override
  Future<QuotaState> recordMeteredConsumption(MeteredActionType actionType) =>
      throw UnimplementedError();
}
