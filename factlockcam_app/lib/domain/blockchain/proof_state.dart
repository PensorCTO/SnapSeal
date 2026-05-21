/// Saga states for asynchronous Polygon notarization.
enum ProofState {
  draft,
  pendingNotarization,
  notarized,
  collision,
  failed,
}

extension ProofStateUiLabel on ProofState {
  /// User-facing copy — avoid blockchain jargon in the UI.
  String get processingLabel {
    switch (this) {
      case ProofState.draft:
        return 'Draft';
      case ProofState.pendingNotarization:
        return 'Generating Proof…';
      case ProofState.notarized:
        return 'Unshakeable Proof Secured';
      case ProofState.collision:
        return 'Proof Conflict';
      case ProofState.failed:
        return 'Proof Pending Retry';
    }
  }
}
