import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/weight_tracking/data/weight_api_exception.dart';
import 'package:pet_profile_app/features/weight_tracking/domain/entities/weight_entry.dart';
import 'package:pet_profile_app/features/weight_tracking/domain/entities/weight_fulfilment_candidates.dart';
import 'package:pet_profile_app/features/weight_tracking/domain/entities/weight_overview.dart';
import 'package:pet_profile_app/features/weight_tracking/domain/entities/weight_write_outcomes.dart';
import 'package:pet_profile_app/features/weight_tracking/domain/repositories/weight_repository.dart';
import 'package:pet_profile_app/features/weight_tracking/presentation/providers/weight_providers.dart';

import '../../../helpers/fakes.dart';

class _MockWeightRepository implements WeightRepository {
  bool undoCalled = false;
  bool throwOnFulfil = false;

  @override
  Future<WeightSaveOutcome> createEntryWithFulfilment(
    WeightEntry entry,
    String fulfilsOccurrenceId,
    String token,
  ) async {
    if (throwOnFulfil) {
      throw WeightApiException(409, 'fulfilment_not_eligible');
    }
    return WeightSaveOutcome(
      entry: entry,
      fulfilment: const WeightFulfilmentOutcome(
        careEntryId: 'care-1',
        undoToken: 'undo-t',
        routineName: 'Weekly',
      ),
    );
  }

  @override
  Future<void> scheduleUndo(
    String careEntryId,
    String undoToken,
    String token,
  ) async {
    undoCalled = true;
  }

  @override
  Future<List<WeightEntry>> getEntries(String petId, String token) async => [];

  @override
  Future<WeightEntry> createEntry(WeightEntry entry, String token) async =>
      entry;

  @override
  Future<WeightSaveOutcome> fulfilEntry(
    String weightEntryId,
    String occurrenceId,
    String token,
  ) async => WeightSaveOutcome(
    entry: WeightEntry(
      id: weightEntryId,
      petId: 'pet-1',
      date: DateTime(2026, 1, 1),
      weight: 10,
    ),
  );

  @override
  Future<WeightEntry> updateEntry(WeightEntry entry, String token) async =>
      entry;

  @override
  Future<WeightDeleteOutcome> deleteEntry(String id, String token) async =>
      const WeightDeleteOutcome();

  @override
  Future<WeightEntry?> getLatestWeight(String petId, String token) async =>
      null;

  @override
  Future<WeightOverview> getOverview(String petId, String token) async =>
      WeightOverview(petId: petId, routines: []);

  @override
  Future<WeightFulfilmentCandidates> getFulfilmentCandidates(
    String petId,
    DateTime date,
    String token,
  ) async => WeightFulfilmentCandidates(date: date, candidates: []);
}

void main() {
  test('FW-9 saveEntry propagates fulfilment_not_eligible', () async {
    final repo = _MockWeightRepository()..throwOnFulfil = true;
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
        weightRepositoryProvider.overrideWithValue(repo),
      ],
    );
    final notifier = container.read(
      weightEntriesNotifierProvider('pet-1').notifier,
    );
    await container.read(weightEntriesNotifierProvider('pet-1').future);

    expect(
      () => notifier.saveEntry(
        entry: WeightEntry(
          id: 'w1',
          petId: 'pet-1',
          date: DateTime(2026, 5, 10),
          weight: 12,
        ),
        fulfilsOccurrenceId: 'occ-1',
      ),
      throwsA(isA<WeightApiException>()),
    );
    container.dispose();
  });

  test('FW-11 undoFulfilment calls repository scheduleUndo', () async {
    final repo = _MockWeightRepository();
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
        weightRepositoryProvider.overrideWithValue(repo),
      ],
    );
    final notifier = container.read(
      weightEntriesNotifierProvider('pet-1').notifier,
    );
    await notifier.undoFulfilment(careEntryId: 'care-1', undoToken: 'undo-t');
    expect(repo.undoCalled, isTrue);
    container.dispose();
  });
}
