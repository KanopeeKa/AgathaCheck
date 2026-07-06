import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/utils/calendar_date.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/recurrence_anchor.dart';
import 'package:pet_profile_app/features/health_tracking/domain/repositories/health_repository.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/controllers/health_entry_form_constants.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/controllers/health_entry_form_controller.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/controllers/health_entry_form_outcomes.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';

class _FakeHealthRepository implements HealthRepository {
  HealthEntry? entryToReturn;

  @override
  Future<HealthEntry?> getEntry(String id) async => entryToReturn;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('HealthEntryFormController', () {
    late ProviderContainer container;
    late _FakeHealthRepository repository;

    HealthEntryFormController controller([
      HealthEntryFormParams params = const HealthEntryFormParams(),
    ]) {
      return container.read(healthEntryFormControllerProvider(params).notifier);
    }

    HealthEntryFormState readState([
      HealthEntryFormParams params = const HealthEntryFormParams(),
    ]) {
      return container.read(healthEntryFormControllerProvider(params));
    }

    setUp(() {
      repository = _FakeHealthRepository();
      container = ProviderContainer(
        overrides: [
          healthRepositoryProvider.overrideWithValue(repository),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('initializes type and pet from params', () {
      const params = HealthEntryFormParams(
        petId: 'pet-1',
        initialType: HealthEntryType.preventive,
      );
      final state = readState(params);
      expect(state.type, HealthEntryType.preventive);
      expect(state.selectedPetIds, {'pet-1'});
      expect(state.isEdit, false);
    });

    test('validateDocument rejects unsupported format and oversized files', () {
      final c = controller();
      expect(
        c.validateDocument('report.exe', 100),
        HealthDocumentValidationError.unsupportedFormat,
      );
      expect(
        c.validateDocument('scan.pdf', healthDocumentMaxBytes + 1),
        HealthDocumentValidationError.tooLarge,
      );
      expect(c.validateDocument('scan.pdf', 1024), isNull);
    });

    test('submit fails when name is empty', () async {
      final c = controller(const HealthEntryFormParams(petId: 'pet-1'));
      c.setDueDate(DateTime(2026, 7, 10));
      final outcome = await c.submit();
      expect(outcome, isA<HealthEntrySubmitValidationFailed>());
      expect(
        (outcome as HealthEntrySubmitValidationFailed).reason,
        HealthEntrySubmitValidation.nameRequired,
      );
    });

    test('submit fails when due and completed dates are both missing', () async {
      final c = controller();
      c.setName('Meds');
      final outcome = await c.submit();
      expect(outcome, isA<HealthEntrySubmitValidationFailed>());
      expect(
        (outcome as HealthEntrySubmitValidationFailed).reason,
        HealthEntrySubmitValidation.dueOrCompletedRequired,
      );
    });

    test('submit fails when no pets are selected', () async {
      final c = controller();
      c.setName('Meds');
      c.setDueDate(DateTime(2026, 7, 10));
      final outcome = await c.submit();
      expect(outcome, isA<HealthEntrySubmitValidationFailed>());
      expect(
        (outcome as HealthEntrySubmitValidationFailed).reason,
        HealthEntrySubmitValidation.noPetsSelected,
      );
    });

    test('prompts to mark completed for past one-off due dates', () {
      final c = controller(const HealthEntryFormParams(petId: 'pet-1'));
      c.setDueDate(calendarDateOnly(DateTime.now().subtract(const Duration(days: 1))));
      final prompt = c.markCompletedPromptIfNeeded();
      expect(prompt, isNotNull);
      expect(prompt!.isPast, isTrue);
    });

    test('loadEntry maps repository entry into form state', () async {
      repository.entryToReturn = HealthEntry(
        id: 'entry-1',
        petId: 'pet-9',
        name: 'Rabies',
        type: HealthEntryType.preventive,
        dosage: '1 ml',
        frequency: HealthFrequency.custom,
        frequencyDays: 14,
        frequencyInterval: 1,
        startDate: DateTime(2026, 1, 1),
        nextDueDate: DateTime(2026, 7, 1),
        completedOn: null,
        recurrenceAnchor: RecurrenceAnchor.fromDueDate,
        notes: 'Annual',
        remindDaysBefore: 3,
      );

      final c = controller();
      final loaded = await c.loadEntry('entry-1');
      final state = readState();

      expect(loaded, isTrue);
      expect(state.name, 'Rabies');
      expect(state.dosage, '1 ml');
      expect(state.notes, 'Annual');
      expect(state.isEdit, isTrue);
      expect(state.type, HealthEntryType.preventive);
      expect(state.frequency, HealthFrequency.daily);
      expect(state.frequencyInterval, 14);
      expect(state.selectedPetIds, {'pet-9'});
      expect(state.remindDaysBefore, 3);
      expect(state.recurrenceAnchor, RecurrenceAnchor.fromDueDate);
    });

    test('setName setDosage setNotes update state', () {
      final c = controller();
      c.setName('Heartgard');
      c.setDosage('1 chew');
      c.setNotes('With food');
      final state = readState();
      expect(state.name, 'Heartgard');
      expect(state.dosage, '1 chew');
      expect(state.notes, 'With food');
    });
  });
}
