import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/experience/presentation/pet_profile/widgets/all_care/all_care_closed.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
HealthEntry _entry({
  required String id,
  String status = 'active',
  HealthFrequency frequency = HealthFrequency.daily,
  DateTime? repeatEndDate,
  DateTime? completedOn,
}) {
  return HealthEntry(
    id: id,
    petId: 'pet-1',
    name: id,
    type: HealthEntryType.medication,
    frequency: frequency,
    startDate: DateTime(2024, 1, 1),
    nextDueDate: DateTime(2024, 6, 1),
    completedOn: completedOn,
    repeatEndDate: repeatEndDate,
    status: status,
    remindDaysBefore: 1,
  );
}

void main() {
  test('isClosedCareListEntry includes closed status and natural end', () {
    expect(isClosedCareListEntry(_entry(id: 'a', status: 'closed')), isTrue);
    expect(
      isClosedCareListEntry(
        _entry(
          id: 'b',
          frequency: HealthFrequency.once,
          completedOn: DateTime(2024, 2, 1),
        ),
      ),
      isTrue,
    );
    expect(isClosedCareListEntry(_entry(id: 'c', status: 'paused')), isFalse);
  });
}
