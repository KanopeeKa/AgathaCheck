import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_taxonomy/domain/care_importance.dart';
import 'package:pet_profile_app/features/care_taxonomy/domain/care_planning_mode.dart';
import 'package:pet_profile_app/features/care_taxonomy/domain/care_setting.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/recurrence_anchor.dart';
import 'package:pet_profile_app/features/health_tracking/domain/repositories/health_repository.dart';
import 'package:pet_profile_app/features/health_tracking/domain/usecases/create_health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/usecases/get_health_entries.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/controllers/health_entry_form_controller.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/controllers/health_entry_form_outcomes.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';

class _CapturingHealthRepository implements HealthRepository {
  HealthEntry? created;

  @override
  Future<HealthEntry> createEntry(HealthEntry entry) async {
    created = entry;
    return entry.copyWith(id: 'created-1');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('HealthEntryFormController planning modes', () {
    late ProviderContainer container;
    late _CapturingHealthRepository repository;

    HealthEntryFormController controller(HealthEntryFormParams params) =>
        container.read(healthEntryFormControllerProvider(params).notifier);

    HealthEntryFormState readState(HealthEntryFormParams params) =>
        container.read(healthEntryFormControllerProvider(params));

    setUp(() {
      repository = _CapturingHealthRepository();
      container = ProviderContainer(
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
    });

    tearDown(() => container.dispose());

    test('record mode initializes with completed date and no reminders', () {
      const params = HealthEntryFormParams(
        petId: 'pet-1',
        initialPlanningMode: CarePlanningMode.unplanned,
      );
      final state = readState(params);

      expect(state.carePlanning, CarePlanningMode.unplanned);
      expect(state.completedOn, isNotNull);
      expect(state.dueDate, isNull);
      expect(state.remindDaysBefore, 0);
      expect(state.frequency, HealthFrequency.once);
    });

    test('switching to record mode clears schedule fields', () {
      const params = HealthEntryFormParams(petId: 'pet-1');
      final c = controller(params);

      c.setDueDate(DateTime(2026, 8, 1));
      c.setFrequency(HealthFrequency.monthly);
      c.setRemindDaysBefore(3);
      c.setCarePlanning(CarePlanningMode.unplanned);

      final state = readState(params);
      expect(state.carePlanning, CarePlanningMode.unplanned);
      expect(state.dueDate, isNull);
      expect(state.frequency, HealthFrequency.once);
      expect(state.remindDaysBefore, 0);
      expect(state.completedOn, isNotNull);
    });

    test(
      'record submit requires completed_on and omits next_due_date',
      () async {
        const params = HealthEntryFormParams(
          petId: 'pet-1',
          initialPlanningMode: CarePlanningMode.unplanned,
        );
        final c = controller(params);

        c.setName('Grooming');
        c.setCareFamily(CareFamily.grooming);
        c.setCompletedOn(null);

        final blocked = await c.submit(skipMarkCompletedCheck: true);
        expect(blocked, isA<HealthEntrySubmitValidationFailed>());
        expect(
          (blocked as HealthEntrySubmitValidationFailed).reason,
          HealthEntrySubmitValidation.completedOnRequired,
        );

        c.setCompletedOn(DateTime(2026, 9, 15));
        final success = await c.submit(skipMarkCompletedCheck: true);
        expect(success, isA<HealthEntrySubmitSuccess>());
        expect(repository.created?.carePlanning, CarePlanningMode.unplanned);
        expect(repository.created?.completedOn, DateTime(2026, 9, 15));
        expect(repository.created?.nextDueDate, isNull);
        expect(repository.created?.frequency, HealthFrequency.once);
        expect(repository.created?.remindDaysBefore, 0);
        expect(repository.created?.careFamily, CareFamily.grooming);
        expect(repository.created?.careSetting, CareSetting.other);
        expect(repository.created?.careImportance, CareImportance.optional);
      },
    );

    test('planned submit keeps due date and reminders', () async {
      const params = HealthEntryFormParams(petId: 'pet-1');
      final c = controller(params);

      c.setName('Vaccine');
      c.setCareFamily(CareFamily.vaccination);
      c.setDueDate(DateTime(2026, 10, 1));
      c.setRemindDaysBefore(7);

      final success = await c.submit(skipMarkCompletedCheck: true);
      expect(success, isA<HealthEntrySubmitSuccess>());
      expect(repository.created?.carePlanning, CarePlanningMode.planned);
      expect(repository.created?.nextDueDate, DateTime(2026, 10, 1));
      expect(repository.created?.completedOn, isNull);
      expect(repository.created?.remindDaysBefore, 7);
    });

    test('record mode skips mark-completed prompt', () {
      const params = HealthEntryFormParams(
        petId: 'pet-1',
        initialPlanningMode: CarePlanningMode.unplanned,
      );
      final c = controller(params);

      expect(c.markCompletedPromptIfNeeded(), isNull);
    });

    test('loadEntry restores care planning from entry', () async {
      repository = _CapturingHealthRepository();
      container = ProviderContainer(
        overrides: [
          healthRepositoryProvider.overrideWithValue(
            _LoadingHealthRepository(),
          ),
        ],
      );

      const params = HealthEntryFormParams(entryId: 'entry-1', petId: 'pet-1');
      final c = controller(params);
      final loaded = await c.loadEntry('entry-1');
      final state = readState(params);

      expect(loaded, isTrue);
      expect(state.carePlanning, CarePlanningMode.unplanned);
      expect(state.completedOn, DateTime(2026, 9, 10));
    });
  });
}

class _LoadingHealthRepository implements HealthRepository {
  @override
  Future<HealthEntry?> getEntry(String id) async => HealthEntry(
    id: id,
    petId: 'pet-1',
    name: 'Grooming',
    type: HealthEntryType.other,
    frequency: HealthFrequency.once,
    frequencyInterval: 1,
    startDate: DateTime(2026, 9, 10),
    completedOn: DateTime(2026, 9, 10),
    recurrenceAnchor: RecurrenceAnchor.fromCompletion,
    careFamily: CareFamily.grooming,
    carePlanning: CarePlanningMode.unplanned,
    careSetting: CareSetting.other,
    careImportance: CareImportance.optional,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
