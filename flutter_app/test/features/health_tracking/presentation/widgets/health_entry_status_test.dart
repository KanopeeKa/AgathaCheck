import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/health_entry_status.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  final l = lookupAppLocalizations(const Locale('en'));
  final date = DateTime(2026, 1, 1);

  test('formatHealthEntryStatusDate uses dd MMM yy', () {
    expect(
      formatHealthEntryStatusDate(date),
      DateFormat('dd MMM yy').format(date),
    );
    expect(formatHealthEntryStatusDate(date), '01 Jan 26');
  });

  test('formatHealthEntryStatusLine shows doneOn for completed entries', () {
    final entry = HealthEntry(
      id: '1',
      petId: 'pet-1',
      name: 'Rabies',
      type: HealthEntryType.preventive,
      frequency: HealthFrequency.once,
      startDate: date,
      completedOn: date,
      nextDueDate: DateTime(9999, 12, 31),
    );

    expect(formatHealthEntryStatusLine(entry, l), l.doneOn('01 Jan 26'));
  });

  test('formatHealthEntryStatusLine shows due date without labels', () {
    final entry = HealthEntry(
      id: '1',
      petId: 'pet-1',
      name: 'Heartgard',
      type: HealthEntryType.medication,
      frequency: HealthFrequency.monthly,
      startDate: date,
      nextDueDate: DateTime(2026, 3, 15),
    );

    expect(formatHealthEntryStatusLine(entry, l), '15 Mar 26');
  });
}
