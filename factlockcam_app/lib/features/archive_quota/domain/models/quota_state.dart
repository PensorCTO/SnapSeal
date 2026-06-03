import 'archive_tier.dart';

/// Credit-based quota counters for pro proofs and verification egress credits.
class QuotaState {
  const QuotaState({
    required this.proProofsRemaining,
    required this.proProofsBase,
    required this.egressCreditsBalance,
    this.cycleEnd,
  });

  final int proProofsRemaining;
  final int proProofsBase;
  final int egressCreditsBalance;
  final DateTime? cycleEnd;

  bool get hasProProofsRemaining => proProofsRemaining > 0;

  bool get hasVerificationCredits => egressCreditsBalance > 0;

  factory QuotaState.fromRpcJson(Map<String, dynamic> json) {
    return QuotaState(
      proProofsRemaining: parseQuotaInt(json['pro_proofs_remaining']),
      proProofsBase: parseQuotaInt(json['pro_proofs_base']),
      egressCreditsBalance: parseQuotaInt(json['egress_credits_balance']),
      cycleEnd: json['cycle_end'] == null
          ? null
          : DateTime.tryParse(json['cycle_end'].toString()),
    );
  }

  QuotaState copyWith({
    int? proProofsRemaining,
    int? proProofsBase,
    int? egressCreditsBalance,
    DateTime? cycleEnd,
  }) {
    return QuotaState(
      proProofsRemaining: proProofsRemaining ?? this.proProofsRemaining,
      proProofsBase: proProofsBase ?? this.proProofsBase,
      egressCreditsBalance: egressCreditsBalance ?? this.egressCreditsBalance,
      cycleEnd: cycleEnd ?? this.cycleEnd,
    );
  }
}
