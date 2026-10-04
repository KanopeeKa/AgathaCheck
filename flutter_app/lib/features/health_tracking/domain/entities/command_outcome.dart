/// Result of a health-store mutation (D19).
///
/// [committed] is true when the server command succeeded.
/// [refreshFailed] is true when reconciliation refresh failed after commit;
/// callers should treat the command as saved and surface a non-blocking refresh hint.
class CommandOutcome {
  const CommandOutcome({required this.committed, this.refreshFailed = false});

  final bool committed;
  final bool refreshFailed;

  @override
  bool operator ==(Object other) {
    return other is CommandOutcome &&
        other.committed == committed &&
        other.refreshFailed == refreshFailed;
  }

  @override
  int get hashCode => Object.hash(committed, refreshFailed);
}
