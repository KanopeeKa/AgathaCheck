import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_taxonomy/domain/care_importance.dart';
import 'package:pet_profile_app/features/care_taxonomy/domain/care_setting.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/recurrence_anchor.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/health_entry_form/health_entry_advanced_settings_summary.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  test('summary joins where, priority, schedule type and late choice', () {
    final l = lookupAppLocalizations(const Locale('en'));
    final text = healthEntryAdvancedSettingsSummary(
      l,
      careSetting: CareSetting.home,
      careImportance: CareImportance.essential,
      frequency: HealthFrequency.daily,
      recurrenceAnchor: RecurrenceAnchor.fromCompletion,
      lateCompletionChoice: null,
    );
    expect(text, contains('At home'));
    expect(text, contains('Essential'));
    expect(text, contains("After it's done"));
    expect(text, contains('Keep the next date'));
  });
}
