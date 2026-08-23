import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/utils/calendar_date.dart';
import 'package:pet_profile_app/features/health_tracking/data/models/health_entry_model.dart';
import 'package:pet_profile_app/features/health_tracking/data/models/health_history_model.dart';
import 'package:pet_profile_app/features/health_tracking/data/models/health_issue_model.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/entry_form_labels.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/health_entry_status.dart';
import 'package:pet_profile_app/features/organization/domain/entities/family_event.dart';
import 'package:pet_profile_app/features/organization/domain/entities/foster_placement.dart';
import 'package:pet_profile_app/features/organization/domain/entities/foster_request.dart';
import 'package:pet_profile_app/features/pet_profile/data/models/pet_model.dart';
import 'package:pet_profile_app/features/weight_tracking/data/models/weight_entry_model.dart';

import '../../helpers/calendar_date_field_expectations.dart';

void main() {
  group(
    'calendar date field inventory (docs/architecture/calendar-dates.md)',
    () {
      expectCalendarDateFieldBehavior(
        entity: 'PetModel',
        field: 'dateOfBirth',
        readParsed: () {
          final model = PetModel.fromJson({
            'id': 'p1',
            'name': 'Buddy',
            'species': 'Dog',
            'dateOfBirth': calendarFieldLegacyUtc,
          });
          return model.dateOfBirth;
        },
        readFromUtcMidnightPicker: () {
          final model = PetModel(
            id: 'p1',
            name: 'Buddy',
            species: 'Dog',
            dateOfBirth: calendarDateOnly(calendarFieldUtcMidnightPicker),
          );
          return model.dateOfBirth;
        },
        readSerializedWire: () {
          final model = PetModel(
            id: 'p1',
            name: 'Buddy',
            species: 'Dog',
            dateOfBirth: calendarDateOnly(calendarFieldUtcMidnightPicker),
          );
          return model.toJson()['dateOfBirth'] as String?;
        },
      );

      expectCalendarDateFieldBehavior(
        entity: 'PetModel',
        field: 'neuteredDate',
        readParsed: () {
          final model = PetModel.fromJson({
            'id': 'p1',
            'name': 'Buddy',
            'species': 'Dog',
            'neuteredDate': calendarFieldIso,
          });
          return model.neuteredDate;
        },
        readFromUtcMidnightPicker: () {
          final model = PetModel(
            id: 'p1',
            name: 'Buddy',
            species: 'Dog',
            neuteredDate: calendarDateOnly(calendarFieldUtcMidnightPicker),
          );
          return model.neuteredDate;
        },
        readSerializedWire: () {
          final model = PetModel(
            id: 'p1',
            name: 'Buddy',
            species: 'Dog',
            neuteredDate: calendarDateOnly(calendarFieldUtcMidnightPicker),
          );
          return model.toJson()['neuteredDate'] as String?;
        },
      );

      expectCalendarDateFieldBehavior(
        entity: 'HealthEntryModel',
        field: 'startDate',
        readParsed: () => HealthEntryModel.fromJson(
          _healthEntryJson({'start_date': calendarFieldIso}),
        ).startDate,
        readFromUtcMidnightPicker: () => HealthEntryModel(
          id: 'e1',
          petId: 'pet1',
          name: 'Meds',
          type: HealthEntryType.medication,
          frequency: HealthFrequency.once,
          startDate: calendarDateOnly(calendarFieldUtcMidnightPicker),
        ).startDate,
        readSerializedWire: () =>
            HealthEntryModel(
                  id: 'e1',
                  petId: 'pet1',
                  name: 'Meds',
                  type: HealthEntryType.medication,
                  frequency: HealthFrequency.once,
                  startDate: calendarDateOnly(calendarFieldUtcMidnightPicker),
                ).toJson()['start_date']
                as String?,
      );

      expectCalendarDateFieldBehavior(
        entity: 'HealthEntryModel',
        field: 'nextDueDate',
        readParsed: () => HealthEntryModel.fromJson(
          _healthEntryJson({'next_due_date': calendarFieldLegacyUtc}),
        ).nextDueDate,
        readFromUtcMidnightPicker: () => HealthEntryModel(
          id: 'e1',
          petId: 'pet1',
          name: 'Meds',
          type: HealthEntryType.medication,
          frequency: HealthFrequency.once,
          startDate: DateTime(2026, 1, 1),
          nextDueDate: calendarDateOnly(calendarFieldUtcMidnightPicker),
        ).nextDueDate,
        readSerializedWire: () =>
            HealthEntryModel(
                  id: 'e1',
                  petId: 'pet1',
                  name: 'Meds',
                  type: HealthEntryType.medication,
                  frequency: HealthFrequency.once,
                  startDate: DateTime(2026, 1, 1),
                  nextDueDate: calendarDateOnly(calendarFieldUtcMidnightPicker),
                ).toJson()['next_due_date']
                as String?,
      );

      expectCalendarDateFieldBehavior(
        entity: 'HealthEntryModel',
        field: 'completedOn',
        readParsed: () => HealthEntryModel.fromJson(
          _healthEntryJson({'completed_on': calendarFieldIso}),
        ).completedOn,
        readFromUtcMidnightPicker: () => HealthEntryModel(
          id: 'e1',
          petId: 'pet1',
          name: 'Meds',
          type: HealthEntryType.medication,
          frequency: HealthFrequency.once,
          startDate: DateTime(2026, 1, 1),
          completedOn: calendarDateOnly(calendarFieldUtcMidnightPicker),
        ).completedOn,
        readSerializedWire: () =>
            HealthEntryModel(
                  id: 'e1',
                  petId: 'pet1',
                  name: 'Meds',
                  type: HealthEntryType.medication,
                  frequency: HealthFrequency.once,
                  startDate: DateTime(2026, 1, 1),
                  completedOn: calendarDateOnly(calendarFieldUtcMidnightPicker),
                ).toJson()['completed_on']
                as String?,
      );

      expectCalendarDateFieldBehavior(
        entity: 'HealthEntryModel',
        field: 'repeatEndDate',
        readParsed: () => HealthEntryModel.fromJson(
          _healthEntryJson({'repeat_end_date': calendarFieldLegacyUtc}),
        ).repeatEndDate,
        readFromUtcMidnightPicker: () => HealthEntryModel(
          id: 'e1',
          petId: 'pet1',
          name: 'Meds',
          type: HealthEntryType.medication,
          frequency: HealthFrequency.weekly,
          startDate: DateTime(2026, 1, 1),
          repeatEndDate: calendarDateOnly(calendarFieldUtcMidnightPicker),
        ).repeatEndDate,
        readSerializedWire: () =>
            HealthEntryModel(
                  id: 'e1',
                  petId: 'pet1',
                  name: 'Meds',
                  type: HealthEntryType.medication,
                  frequency: HealthFrequency.weekly,
                  startDate: DateTime(2026, 1, 1),
                  repeatEndDate: calendarDateOnly(
                    calendarFieldUtcMidnightPicker,
                  ),
                ).toJson()['repeat_end_date']
                as String?,
      );

      expectCalendarDateFieldBehavior(
        entity: 'HealthIssueModel',
        field: 'startDate',
        readParsed: () => HealthIssueModel.fromJson({
          'id': 'hi1',
          'pet_id': 'pet1',
          'title': 'Issue',
          'start_date': calendarFieldIso,
        }).startDate,
        readFromUtcMidnightPicker: () => HealthIssueModel(
          id: 'hi1',
          petId: 'pet1',
          title: 'Issue',
          startDate: calendarDateOnly(calendarFieldUtcMidnightPicker),
        ).startDate,
        readSerializedWire: () =>
            HealthIssueModel(
                  id: 'hi1',
                  petId: 'pet1',
                  title: 'Issue',
                  startDate: calendarDateOnly(calendarFieldUtcMidnightPicker),
                ).toJson()['start_date']
                as String?,
      );

      expectCalendarDateFieldBehavior(
        entity: 'HealthIssueModel',
        field: 'endDate',
        readParsed: () => HealthIssueModel.fromJson({
          'id': 'hi1',
          'pet_id': 'pet1',
          'title': 'Issue',
          'end_date': calendarFieldLegacyUtc,
        }).endDate,
        readFromUtcMidnightPicker: () => HealthIssueModel(
          id: 'hi1',
          petId: 'pet1',
          title: 'Issue',
          endDate: calendarDateOnly(calendarFieldUtcMidnightPicker),
        ).endDate,
        readSerializedWire: () =>
            HealthIssueModel(
                  id: 'hi1',
                  petId: 'pet1',
                  title: 'Issue',
                  endDate: calendarDateOnly(calendarFieldUtcMidnightPicker),
                ).toJson()['end_date']
                as String?,
      );

      expectCalendarDateFieldBehavior(
        entity: 'HealthHistoryModel',
        field: 'dueDate',
        readParsed: () => HealthHistoryModel.fromJson({
          'id': 'hh1',
          'health_entry_id': 'e1',
          'marked_at': '2026-12-19T10:00:00.000Z',
          'due_date': calendarFieldIso,
        }).dueDate,
        readFromUtcMidnightPicker: () => HealthHistoryModel(
          id: 'hh1',
          entryId: 'e1',
          markedAt: DateTime.utc(2026, 12, 19, 10),
          dueDate: calendarDateOnly(calendarFieldUtcMidnightPicker),
        ).dueDate,
      );

      expectCalendarDateFieldBehavior(
        entity: 'HealthHistoryModel',
        field: 'completedOn',
        readParsed: () => HealthHistoryModel.fromJson({
          'id': 'hh1',
          'health_entry_id': 'e1',
          'marked_at': '2026-12-19T10:00:00.000Z',
          'completed_on': calendarFieldLegacyUtc,
        }).completedOn,
        readFromUtcMidnightPicker: () => HealthHistoryModel(
          id: 'hh1',
          entryId: 'e1',
          markedAt: DateTime.utc(2026, 12, 19, 10),
          completedOn: calendarDateOnly(calendarFieldUtcMidnightPicker),
        ).completedOn,
      );

      expectCalendarDateFieldBehavior(
        entity: 'WeightEntryModel',
        field: 'date',
        readParsed: () => WeightEntryModel.fromJson({
          'id': 'w1',
          'pet_id': 'pet1',
          'date': calendarFieldIso,
          'weight': 12.5,
        }).date,
        readFromUtcMidnightPicker: () => WeightEntryModel(
          id: 'w1',
          petId: 'pet1',
          date: calendarDateOnly(calendarFieldUtcMidnightPicker),
          weight: 12.5,
        ).date,
        readSerializedWire: () =>
            WeightEntryModel(
                  id: 'w1',
                  petId: 'pet1',
                  date: calendarDateOnly(calendarFieldUtcMidnightPicker),
                  weight: 12.5,
                ).toJson()['date']
                as String?,
      );

      expectCalendarDateFieldBehavior(
        entity: 'FamilyEvent',
        field: 'fromDate',
        readParsed: () => FamilyEvent.fromJson({
          'id': 'fe1',
          'pet_id': 'pet1',
          'organization_id': 'org1',
          'from_date': calendarFieldLegacyUtc,
        }).fromDate,
        readFromUtcMidnightPicker: () {
          final event = FamilyEvent.fromJson({
            'id': 'fe1',
            'pet_id': 'pet1',
            'organization_id': 'org1',
            'from_date': toCalendarDateString(
              calendarDateOnly(calendarFieldUtcMidnightPicker),
            ),
          });
          return event.fromDate;
        },
      );

      expectCalendarDateFieldBehavior(
        entity: 'FamilyEvent',
        field: 'toDate',
        readParsed: () => FamilyEvent.fromJson({
          'id': 'fe1',
          'pet_id': 'pet1',
          'organization_id': 'org1',
          'from_date': '2026-01-01',
          'to_date': calendarFieldIso,
        }).toDate,
        readFromUtcMidnightPicker: () {
          final event = FamilyEvent.fromJson({
            'id': 'fe1',
            'pet_id': 'pet1',
            'organization_id': 'org1',
            'from_date': '2026-01-01',
            'to_date': toCalendarDateString(
              calendarDateOnly(calendarFieldUtcMidnightPicker),
            ),
          });
          return event.toDate;
        },
      );

      expectCalendarDateFieldBehavior(
        entity: 'FosterPlacement',
        field: 'startDate',
        readParsed: () => FosterPlacement.fromJson({
          'id': 'fp1',
          'organization_id': 'org1',
          'pet_id': 'pet1',
          'foster_user_id': 'user1',
          'status': 'in_progress',
          'start_date': calendarFieldIso,
        }).startDate,
        readFromUtcMidnightPicker: () => FosterPlacement(
          id: 'fp1',
          organizationId: 'org1',
          petId: 'pet1',
          fosterUserId: 'user1',
          status: 'in_progress',
          startDate: calendarDateOnly(calendarFieldUtcMidnightPicker),
        ).startDate,
      );

      expectCalendarDateFieldBehavior(
        entity: 'FosterPlacement',
        field: 'endDate',
        readParsed: () => FosterPlacement.fromJson({
          'id': 'fp1',
          'organization_id': 'org1',
          'pet_id': 'pet1',
          'foster_user_id': 'user1',
          'status': 'not_in_foster',
          'end_date': calendarFieldLegacyUtc,
        }).endDate,
        readFromUtcMidnightPicker: () => FosterPlacement(
          id: 'fp1',
          organizationId: 'org1',
          petId: 'pet1',
          fosterUserId: 'user1',
          status: 'not_in_foster',
          endDate: calendarDateOnly(calendarFieldUtcMidnightPicker),
        ).endDate,
      );

      expectCalendarDateFieldBehavior(
        entity: 'FosterRequestResponse',
        field: 'earliestAvailability',
        readParsed: () => FosterRequestResponse.fromJson({
          'id': 'fr1',
          'org_foster_parent_id': 'ofp1',
          'response': 'can_help',
          'earliest_availability': calendarFieldIso,
        }).earliestAvailability,
        readFromUtcMidnightPicker: () => FosterRequestResponse(
          id: 'fr1',
          orgFosterParentId: 'ofp1',
          response: FosterResponseType.canHelp,
          earliestAvailability: calendarDateOnly(
            calendarFieldUtcMidnightPicker,
          ),
        ).earliestAvailability,
      );
    },
  );

  group('display formatters', () {
    test('formatEntryDate matches dd/MM/yyyy for UTC-midnight picker', () {
      final normalized = calendarDateOnly(calendarFieldUtcMidnightPicker);
      expect(formatEntryDate(normalized), calendarFieldDisplay);
    });

    test('formatHealthEntryStatusDate preserves calendar day', () {
      final normalized = calendarDateOnly(calendarFieldUtcMidnightPicker);
      expect(formatHealthEntryStatusDate(normalized), contains('18'));
      expect(formatHealthEntryStatusDate(normalized), isNot(contains('17')));
    });
  });
}

Map<String, dynamic> _healthEntryJson(Map<String, dynamic> overrides) => {
  'id': 'e1',
  'pet_id': 'pet1',
  'name': 'Meds',
  'type': 'medication',
  'frequency': 'once',
  'start_date': '2026-01-01',
  ...overrides,
};
