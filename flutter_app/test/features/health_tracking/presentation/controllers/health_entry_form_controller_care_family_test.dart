import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/repositories/health_repository.dart';
import 'package:pet_profile_app/features/health_tracking/domain/usecases/create_health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/usecases/get_health_entries.dart';
import 'package:pet_profile_app/features/health_tracking/domain/usecases/update_health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/controllers/health_entry_form_controller.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/controllers/health_entry_form_outcomes.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';

class _CapturingHealthRepository implements HealthRepository {
  HealthEntry? created;
  HealthEntry? updated;

  @override
  Future<HealthEntry> createEntry(HealthEntry entry) async {
    created = entry;
    return entry.copyWith(id: 'created-1');
  }

  @override
  Future<HealthEntry?> getEntry(String id) async => HealthEntry(
    id: id,
    petId: 'p1',
    name: 'Heartworm',
    type: HealthEntryType.preventive,
    dosage: '',
    frequency: HealthFrequency.monthly,
    frequencyInterval: 1,
    startDate: DateTime(2025, 1, 1),
    nextDueDate: DateTime(2025, 8, 1),
    careFamily: null,
  );

  @override
  Future<List<HealthEntry>> getEntries({
    String? petId,
    HealthEntryType? type,
  }) async => [];

  @override
  Future<HealthEntry> updateEntry(HealthEntry entry) async {
    updated = entry;
    return entry;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('create requires care family before submit succeeds', () async {
    final repository = _CapturingHealthRepository();
    final container = ProviderContainer(
      overrides: [
        healthRepositoryProvider.overrideWithValue(repository),
        createHealthEntryProvider.overrideWithValue(
          CreateHealthEntry(repository),
        ),
        getHealthEntriesProvider.overrideWithValue(
          GetHealthEntries(repository),
        ),
      ],
    );

    final params = const HealthEntryFormParams(petId: 'p1');
    final controller = container.read(
      healthEntryFormControllerProvider(params).notifier,
    );

    controller.setName('Evening pill');
    controller.setCompletedOn(DateTime(2025, 9, 1));

    final blocked = await controller.submit();
    expect(blocked, isA<HealthEntrySubmitValidationFailed>());

    controller.setCareFamily(CareFamily.medication);
    final success = await controller.submit(skipMarkCompletedCheck: true);
    expect(success, isA<HealthEntrySubmitSuccess>());
    expect(repository.created?.careFamily, CareFamily.medication);

    container.dispose();
  });

  test('edit uncategorised entry saves without accepting suggestion', () async {
    final repository = _CapturingHealthRepository();
    final container = ProviderContainer(
      overrides: [
        healthRepositoryProvider.overrideWithValue(repository),
        updateHealthEntryProvider.overrideWithValue(
          UpdateHealthEntry(repository),
        ),
        getHealthEntriesProvider.overrideWithValue(
          GetHealthEntries(repository),
        ),
      ],
    );

    final params = const HealthEntryFormParams(entryId: 'entry-1', petId: 'p1');
    final controller = container.read(
      healthEntryFormControllerProvider(params).notifier,
    );

    await controller.loadEntry('entry-1');
    controller.dismissCareFamilySuggestion();

    final outcome = await controller.submit();
    expect(outcome, isA<HealthEntrySubmitSuccess>());
    expect(repository.updated?.careFamily, isNull);

    container.dispose();
  });
}
