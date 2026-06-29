import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/health_tracking/data/models/health_entry_model.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';

void main() {
  group('HealthEntryModel', () {
    final fullJson = {
      'id': 'abc-123',
      'pet_id': 'pet-1',
      'name': 'Heartgard',
      'type': 'medication',
      'dosage': '1 tablet',
      'frequency': 'monthly',
      'frequency_days': 30,
      'frequency_interval': 2,
      'repeat_end_date': '2026-01-01',
      'start_date': '2025-01-01',
      'next_due_date': '2025-02-01T09:00:00.000Z',
      'notes': 'Give with food',
      'health_issue_id': 'issue-42',
      'health_issue_title': 'Heart condition',
      'remind_days_before': 3,
      'created_at': '2025-01-01T00:00:00.000Z',
      'updated_at': '2025-01-15T00:00:00.000Z',
    };

    test('fromJson parses all fields correctly', () {
      final model = HealthEntryModel.fromJson(fullJson);
      expect(model.id, 'abc-123');
      expect(model.petId, 'pet-1');
      expect(model.name, 'Heartgard');
      expect(model.type, HealthEntryType.medication);
      expect(model.dosage, '1 tablet');
      expect(model.frequency, HealthFrequency.monthly);
      expect(model.frequencyDays, 30);
      expect(model.frequencyInterval, 2);
      expect(model.repeatEndDate, isNotNull);
      expect(model.repeatEndDate!.year, 2026);
      expect(model.startDate.year, 2025);
      expect(model.startDate.month, 1);
      expect(model.startDate.day, 1);
      expect(model.nextDueDate!.year, 2025);
      expect(model.nextDueDate!.month, 2);
      expect(model.nextDueDate!.day, 1);
      expect(model.notes, 'Give with food');
      expect(model.healthIssueId, 'issue-42');
      expect(model.healthIssueName, 'Heart condition');
      expect(model.remindDaysBefore, 3);
      expect(model.createdAt, isNotNull);
      expect(model.createdAt!.year, 2025);
      expect(model.updatedAt, isNotNull);
      expect(model.updatedAt!.month, 1);
      expect(model.updatedAt!.day, 15);
    });

    test('fromJson handles missing optional fields', () {
      final minimalJson = {
        'id': 'x',
        'name': 'Test',
        'type': 'vaccine',
        'frequency': 'weekly',
        'start_date': '2025-06-01',
        'next_due_date': '2025-06-08T00:00:00.000Z',
      };
      final model = HealthEntryModel.fromJson(minimalJson);
      expect(model.petId, '');
      expect(model.dosage, '');
      expect(model.notes, '');
      expect(model.frequencyDays, isNull);
      expect(model.frequencyInterval, 1);
      expect(model.repeatEndDate, isNull);
      expect(model.healthIssueId, isNull);
      expect(model.healthIssueName, isNull);
      expect(model.remindDaysBefore, 1);
      expect(model.createdAt, isNull);
      expect(model.updatedAt, isNull);
      expect(model.type, HealthEntryType.preventive);
      expect(model.frequency, HealthFrequency.weekly);
    });

    test('fromJson defaults unknown type to medication', () {
      final json = {...fullJson, 'type': 'unknown'};
      final model = HealthEntryModel.fromJson(json);
      expect(model.type, HealthEntryType.medication);
    });

    test('fromJson defaults unknown frequency to once', () {
      final json = {...fullJson, 'frequency': 'biweekly'};
      final model = HealthEntryModel.fromJson(json);
      expect(model.frequency, HealthFrequency.once);
    });

    test('fromJson parses all entry types', () {
      final expected = {
        'medication': HealthEntryType.medication,
        'preventive': HealthEntryType.preventive,
        'vaccine': HealthEntryType.preventive,
        'vet_visit': HealthEntryType.vetVisit,
        'vetVisit': HealthEntryType.vetVisit,
        'procedure': HealthEntryType.procedure,
        'family_event': HealthEntryType.familyEvent,
        'familyEvent': HealthEntryType.familyEvent,
      };
      for (final entry in expected.entries) {
        final model =
            HealthEntryModel.fromJson({...fullJson, 'type': entry.key});
        expect(model.type, entry.value,
            reason: 'type "${entry.key}" should parse to ${entry.value}');
      }
    });

    test('fromJson parses all frequencies', () {
      final expected = {
        'once': HealthFrequency.once,
        'daily': HealthFrequency.daily,
        'weekly': HealthFrequency.weekly,
        'monthly': HealthFrequency.monthly,
        'yearly': HealthFrequency.yearly,
        'custom': HealthFrequency.custom,
      };
      for (final entry in expected.entries) {
        final model = HealthEntryModel.fromJson(
            {...fullJson, 'frequency': entry.key});
        expect(model.frequency, entry.value);
      }
    });

    test('toJson produces correct map with all fields', () {
      final model = HealthEntryModel.fromJson(fullJson);
      final json = model.toJson();
      expect(json['id'], 'abc-123');
      expect(json['pet_id'], 'pet-1');
      expect(json['name'], 'Heartgard');
      expect(json['type'], 'medication');
      expect(json['dosage'], '1 tablet');
      expect(json['frequency'], 'monthly');
      expect(json['frequency_days'], 30);
      expect(json['frequency_interval'], 2);
      expect(json['repeat_end_date'], isNotNull);
      expect(json['notes'], 'Give with food');
      expect(json['health_issue_id'], 'issue-42');
      expect(json['remind_days_before'], 3);
    });

    test('toJson omits health_issue_id when null', () {
      final json = {...fullJson};
      json.remove('health_issue_id');
      final model = HealthEntryModel.fromJson(json);
      final output = model.toJson();
      expect(output.containsKey('health_issue_id'), isFalse);
    });

    test('toJson serializes vet_visit type correctly', () {
      final json = {...fullJson, 'type': 'vet_visit'};
      final model = HealthEntryModel.fromJson(json);
      final output = model.toJson();
      expect(output['type'], 'vet_visit');
    });

    test('toJson serializes family_event type correctly', () {
      final json = {...fullJson, 'type': 'family_event'};
      final model = HealthEntryModel.fromJson(json);
      final output = model.toJson();
      expect(output['type'], 'family_event');
    });

    test('toJson serializes every type to its canonical API string', () {
      // Regression guard against using enum.name (minified in release builds).
      final expected = {
        HealthEntryType.medication: 'medication',
        HealthEntryType.preventive: 'preventive',
        HealthEntryType.vetVisit: 'vet_visit',
        HealthEntryType.procedure: 'procedure',
        HealthEntryType.familyEvent: 'family_event',
      };
      for (final entry in expected.entries) {
        expect(HealthEntryModel.typeToApi(entry.key), entry.value);
        // Each canonical string must also round-trip back to the same enum.
        final restored = HealthEntryModel.fromJson({...fullJson, 'type': entry.value});
        expect(restored.type, entry.key);
      }
    });

    test('toJson serializes every frequency to its canonical API string', () {
      final expected = {
        HealthFrequency.once: 'once',
        HealthFrequency.daily: 'daily',
        HealthFrequency.weekly: 'weekly',
        HealthFrequency.monthly: 'monthly',
        HealthFrequency.yearly: 'yearly',
        HealthFrequency.custom: 'custom',
      };
      for (final entry in expected.entries) {
        expect(HealthEntryModel.frequencyToApi(entry.key), entry.value);
        final restored =
            HealthEntryModel.fromJson({...fullJson, 'frequency': entry.value});
        expect(restored.frequency, entry.key);
      }
    });

    test('preventive and procedure types survive a toJson/fromJson round-trip', () {
      // These previously used enum.name in toJson and would corrupt to
      // medication after a round-trip in a release build.
      for (final type in [HealthEntryType.preventive, HealthEntryType.procedure]) {
        final model = HealthEntryModel(
          id: 'r-1',
          petId: 'pet-1',
          name: 'Test',
          type: type,
          frequency: HealthFrequency.monthly,
          startDate: DateTime(2025, 1, 1),
          nextDueDate: DateTime(2025, 2, 1),
        );
        final restored = HealthEntryModel.fromJson(model.toJson());
        expect(restored.type, type);
      }
    });

    test('fromEntity preserves all data', () {
      final entity = HealthEntry(
        id: 'e-1',
        petId: 'p-1',
        name: 'Rabies',
        type: HealthEntryType.preventive,
        dosage: '1ml',
        frequency: HealthFrequency.custom,
        frequencyDays: 365,
        frequencyInterval: 1,
        repeatEndDate: DateTime(2030, 1, 1),
        startDate: DateTime(2025, 3, 1),
        nextDueDate: DateTime(2026, 3, 1),
        notes: 'Annual',
        healthIssueId: 'hi-1',
        healthIssueName: 'Rabies prevention',
        remindDaysBefore: 7,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 2, 1),
      );
      final model = HealthEntryModel.fromEntity(entity);
      expect(model.id, entity.id);
      expect(model.petId, entity.petId);
      expect(model.name, entity.name);
      expect(model.type, entity.type);
      expect(model.dosage, entity.dosage);
      expect(model.frequency, entity.frequency);
      expect(model.frequencyDays, 365);
      expect(model.frequencyInterval, 1);
      expect(model.repeatEndDate, entity.repeatEndDate);
      expect(model.startDate, entity.startDate);
      expect(model.nextDueDate, entity.nextDueDate);
      expect(model.notes, entity.notes);
      expect(model.healthIssueId, entity.healthIssueId);
      expect(model.healthIssueName, entity.healthIssueName);
      expect(model.remindDaysBefore, 7);
      expect(model.createdAt, entity.createdAt);
      expect(model.updatedAt, entity.updatedAt);
    });

    test('toJson round-trips through fromJson', () {
      final original = HealthEntryModel.fromJson(fullJson);
      final json = original.toJson();
      final restored = HealthEntryModel.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.type, original.type);
      expect(restored.frequency, original.frequency);
      expect(restored.frequencyDays, original.frequencyDays);
      expect(restored.frequencyInterval, original.frequencyInterval);
      expect(restored.healthIssueId, original.healthIssueId);
      expect(restored.remindDaysBefore, original.remindDaysBefore);
    });

    test('fromJson preserves calendar day from date-only API responses', () {
      final model = HealthEntryModel.fromJson({
        ...fullJson,
        'start_date': '2026-06-30',
        'next_due_date': '2026-06-30',
      });
      expect(model.startDate.year, 2026);
      expect(model.startDate.month, 6);
      expect(model.startDate.day, 30);
      expect(model.nextDueDate!.year, 2026);
      expect(model.nextDueDate!.month, 6);
      expect(model.nextDueDate!.day, 30);
    });

    test('fromJson uses date portion of legacy UTC timestamp responses', () {
      // Older API responses used toISOString(); the calendar date is the Y-M-D prefix.
      final model = HealthEntryModel.fromJson({
        ...fullJson,
        'start_date': '2026-06-30T00:00:00.000Z',
        'next_due_date': '2026-06-30T00:00:00.000Z',
      });
      expect(model.startDate.day, 30);
      expect(model.nextDueDate!.day, 30);
    });

    test('toJson serializes next_due_date as date-only', () {
      final model = HealthEntryModel(
        id: 'e-1',
        petId: 'pet-1',
        name: 'Test',
        type: HealthEntryType.medication,
        frequency: HealthFrequency.once,
        startDate: DateTime(2026, 6, 30),
        nextDueDate: DateTime(2026, 6, 30),
      );
      final json = model.toJson();
      expect(json['start_date'], '2026-06-30');
      expect(json['next_due_date'], '2026-06-30');
      expect(json['next_due_date'], isNot(contains('T')));
    });
  });
}
