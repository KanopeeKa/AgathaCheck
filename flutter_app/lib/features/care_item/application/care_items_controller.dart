import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/care_item_schedule.dart';
import 'care_command_outcome.dart';
import 'care_completion_service.dart';

/// Care items with their open occurrences, as the server last confirmed them.
class CareItemsState {
  const CareItemsState({
    this.items = const {},
    this.loading = false,
    this.failure,
  });

  /// By care item id.
  final Map<String, CareItemSchedule> items;
  final bool loading;
  final CareCommandFailure? failure;

  CareItemsState copyWith({
    Map<String, CareItemSchedule>? items,
    bool? loading,
    CareCommandFailure? failure,
    bool clearFailure = false,
  }) {
    return CareItemsState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}

/// Single owner of care items and their open occurrences (§7.3, C1).
///
/// Rows read from here; nothing changes before the server confirms (UIR-2):
/// a command result replaces its item, or the item is reloaded when the
/// route does not return it. One list read, no per-row fetch.
class CareItemsController extends StateNotifier<CareItemsState> {
  CareItemsController(this._service, {this.petId})
    : super(const CareItemsState());

  final CareCompletionService _service;
  final String? petId;

  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearFailure: true);
    final outcome = await _service.fetchCareItems(petId: petId);
    if (!mounted) return;
    switch (outcome) {
      case CareSucceeded(:final value):
        state = CareItemsState(items: {for (final s in value) s.entryId: s});
      case CareFailed(:final failure):
        state = state.copyWith(loading: false, failure: failure);
    }
  }

  /// Apply a confirmed command. Without the item in the answer, reload it.
  Future<void> applyResult(CareCommandResult result) async {
    final schedule = result.schedule;
    if (schedule != null) {
      _put(schedule);
      return;
    }
    await reloadItem(result.entryId);
  }

  Future<void> reloadItem(String entryId) async {
    final outcome = await _service.fetchCareItem(entryId);
    if (!mounted) return;
    switch (outcome) {
      case CareSucceeded(:final value):
        _put(value);
      case CareFailed(failure: CareNotOpenFailure(gone: true)):
        state = state.copyWith(items: {...state.items}..remove(entryId));
      case CareFailed(:final failure):
        state = state.copyWith(failure: failure);
    }
  }

  void _put(CareItemSchedule schedule) {
    if (petId != null && schedule.petId != petId) return;
    state = state.copyWith(items: {...state.items, schedule.entryId: schedule});
  }
}
