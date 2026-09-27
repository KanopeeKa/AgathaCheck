import 'package:flutter/material.dart';

import '../../../../core/utils/calendar_date.dart';
import '../../domain/entities/health_occurrence.dart';
import '../../domain/occurrence_missed.dart';
import 'overdue_completion_sheet.dart';

/// Resolves the completion calendar day for [occurrence] (D-CIE-009).
///
/// Due and coming-up slots complete as today without a sheet. Overdue slots
/// prompt for when the care was actually done.
Future<DateTime?> resolveCompletedOnForOccurrence(
  BuildContext context,
  HealthOccurrence occurrence, {
  DateTime? now,
}) async {
  final clock = now ?? DateTime.now();
  final missed = occurrence.missed || isOccurrenceMissed(occurrence, clock);
  if (!missed) {
    return calendarDateOnly(clock);
  }
  if (!context.mounted) return null;
  return showOverdueCompletionSheet(
    context,
    occurrence: occurrence,
    now: clock,
  );
}
