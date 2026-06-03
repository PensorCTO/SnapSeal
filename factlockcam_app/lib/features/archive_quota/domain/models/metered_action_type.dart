/// Credit-metered actions debited against subscription cycles.
enum MeteredActionType {
  proProof('pro_proof'),
  verificationCredit('verification_credit');

  const MeteredActionType(this.rpcValue);

  final String rpcValue;
}
