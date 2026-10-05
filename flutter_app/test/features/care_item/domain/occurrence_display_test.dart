import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_item/domain/care_occurrence.dart';
import 'package:pet_profile_app/features/care_item/domain/occurrence_detail.dart';
import 'package:pet_profile_app/features/care_item/domain/occurrence_display.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  late AppLocalizations l;

  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('en'));
  });

  test('open not_recorded shows as Overdue', () {
    final pill = openOccurrencePillStyle(l, CareOccurrenceStatus.notRecorded);
    expect(pill.label, l.urgencyOverdue);
    expect(pill.tone, OccurrencePillTone.overdue);
  });

  test('closed not recorded pill is neutral grey tone', () {
    final pill = closedNotRecordedPillStyle(l);
    expect(pill.label, contains('Not recorded'));
    expect(pill.label, contains('closed'));
    expect(pill.tone, OccurrencePillTone.closedNotRecorded);
  });

  test('occurrence status line maps open not_recorded to Overdue', () {
    final occ = CareOccurrence(
      id: '1',
      date: DateTime(2026, 10, 2),
      time: '08:00',
      status: CareOccurrenceStatus.notRecorded,
      origin: CareOccurrenceOrigin.schedule,
      isOpen: true,
    );
    expect(occurrenceStatusLine(l, occ), l.urgencyOverdue);
  });
}
