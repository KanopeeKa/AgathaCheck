part of 'health_providers.dart';

/// Manages the state of health entries with async loading.
final healthEntriesNotifierProvider =
    AsyncNotifierProvider<HealthEntriesNotifier, List<HealthEntry>>(
      HealthEntriesNotifier.new,
    );

/// Canonical in-memory owner for health entries (Package 8 / D19).
class HealthEntriesNotifier extends AsyncNotifier<List<HealthEntry>> {
  int _fetchGeneration = 0;
  int _sessionEpoch = 0;
  int _buildGeneration = 0;

  bool _isActive(int generation, int session) {
    return generation == _fetchGeneration && session == _sessionEpoch;
  }

  void _bindSessionGuard() {
    ref.listen<String?>(authProvider.select((auth) => auth.user?.id), (
      previous,
      next,
    ) {
      if (previous == next) return;
      _sessionEpoch++;
      _fetchGeneration++;
      state = const AsyncLoading<List<HealthEntry>>();
      ref.invalidateSelf();
    });
  }

  Future<List<HealthEntry>> _fetchEntries() {
    return ref.read(getHealthEntriesProvider).call();
  }

  Future<bool> _reconcileAfterMutation() async {
    final generation = ++_fetchGeneration;
    final session = _sessionEpoch;
    final snapshot = state;
    state = const AsyncLoading<List<HealthEntry>>().copyWithPrevious(snapshot);
    try {
      final entries = await _fetchEntries();
      if (!_isActive(generation, session)) return false;
      state = AsyncData(entries);
      return false;
    } catch (error, stackTrace) {
      if (!_isActive(generation, session)) return false;
      state = AsyncError<List<HealthEntry>>(
        error,
        stackTrace,
      ).copyWithPrevious(snapshot);
      return true;
    }
  }

  Future<CommandOutcome> _runCommittedCommand(
    Future<void> Function() command,
  ) async {
    await command();
    final refreshFailed = await _reconcileAfterMutation();
    return CommandOutcome(committed: true, refreshFailed: refreshFailed);
  }

  @override
  Future<List<HealthEntry>> build() async {
    ref.watch(authProvider);
    _bindSessionGuard();
    final buildGeneration = ++_buildGeneration;
    final generation = ++_fetchGeneration;
    final session = _sessionEpoch;
    final entries = await _fetchEntries();
    if (buildGeneration != _buildGeneration ||
        !_isActive(generation, session)) {
      return state.valueOrNull ?? <HealthEntry>[];
    }
    return entries;
  }

  /// Refreshes the list of health entries from the server.
  Future<void> refresh() async {
    final generation = ++_fetchGeneration;
    final session = _sessionEpoch;
    final snapshot = state;
    state = const AsyncLoading<List<HealthEntry>>().copyWithPrevious(snapshot);
    try {
      final entries = await _fetchEntries();
      if (!_isActive(generation, session)) return;
      state = AsyncData(entries);
    } catch (error, stackTrace) {
      if (!_isActive(generation, session)) return;
      state = AsyncError<List<HealthEntry>>(
        error,
        stackTrace,
      ).copyWithPrevious(snapshot);
    }
  }

  /// Creates a new health entry and reconciles from the server.
  Future<CommandOutcome> create(HealthEntry entry) {
    return _runCommittedCommand(
      () => ref.read(createHealthEntryProvider).call(entry),
    );
  }

  /// Updates an existing health entry and reconciles from the server.
  Future<CommandOutcome> updateEntry(HealthEntry entry) {
    return _runCommittedCommand(
      () => ref.read(updateHealthEntryProvider).call(entry),
    );
  }

  /// Deletes a health entry by [id] and reconciles from the server.
  Future<CommandOutcome> delete(String id) {
    return _runCommittedCommand(
      () => ref.read(deleteHealthEntryProvider).call(id),
    );
  }

  /// Completes the leading open occurrence for [id] (occurrence-first mark-done).
  Future<CommandOutcome> markTaken(
    String id, {
    String notes = '',
    DateTime? completedOn,
  }) {
    return _runCommittedCommand(() async {
      final repository = ref.read(healthRepositoryProvider);
      final occurrences = await repository.getOpenOccurrences(id);
      if (occurrences.isEmpty) {
        throw StateError('No open occurrence to complete for $id');
      }
      final HealthOccurrence head = occurrences.first;
      await repository.completeOccurrence(
        id,
        head.id,
        notes: notes,
        completedOn: completedOn,
      );
    });
  }

  /// Undoes the last schedule command on the entry.
  Future<CommandOutcome> undoComplete(String id) {
    return _runCommittedCommand(
      () => ref.read(healthRepositoryProvider).unmarkDone(id),
    );
  }

  /// Closes an event (status completed, repeat end yesterday).
  Future<CommandOutcome> closeEvent(String id) {
    return _runCommittedCommand(
      () => ref.read(healthRepositoryProvider).closeEvent(id),
    );
  }

  /// Reopens a closed event (clears repeat end and next due date).
  Future<CommandOutcome> reopenEvent(String id) {
    return _runCommittedCommand(
      () => ref.read(healthRepositoryProvider).reopenEvent(id),
    );
  }

  Future<CommandOutcome> pauseCareItem(String id) {
    return _runCommittedCommand(
      () => ref.read(healthRepositoryProvider).pauseCareItem(id),
    );
  }

  Future<CommandOutcome> resumeCareItem(String id) {
    return _runCommittedCommand(
      () => ref.read(healthRepositoryProvider).resumeCareItem(id),
    );
  }

  /// Unmarks the last completed occurrence.
  Future<CommandOutcome> unmarkDone(String id) {
    return _runCommittedCommand(
      () => ref.read(healthRepositoryProvider).unmarkDone(id),
    );
  }
}
