import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/care_period_coverage.dart';
import 'package:pet_profile_app/features/pet_care/context/presentation/away_plan_schedule_copy.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  late AppLocalizations l;

  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('en'));
  });

  test('routineRowTitle prefixes conditional rows', () {
    expect(
      AwayPlanScheduleCopy.routineRowTitle(
        const CarePeriodRoutineItem(
          healthEntryId: 'e1',
          name: 'Evening pill',
          type: 'medication',
          careFamily: 'medication',
          certainty: 'conditional_on_future_completion',
          occurrenceCount: 2,
          status: 'pending',
          firstScheduledDate: '2026-08-12',
          lastScheduledDate: '2026-08-13',
        ),
      ),
      '~ Evening pill',
    );
  });

  test('datedRowStatus maps pending status', () {
    final text = AwayPlanScheduleCopy.datedRowStatus(
      l,
      const CarePeriodProjectionItem(
        healthEntryId: 'e1',
        scheduledDate: '2026-08-14',
        status: 'pending',
        source: 'projected',
        name: 'Monthly tablet',
        type: 'medication',
        careFamily: 'medication',
      ),
    );
    expect(text, startsWith('Due '));
  });

  test('indeterminateRowSubtitle maps from_completion_pending', () {
    final text = AwayPlanScheduleCopy.indeterminateRowSubtitle(
      l,
      const CarePeriodUncertainty(
        healthEntryId: 'e1',
        reason: 'from_completion_pending',
        name: 'Booster',
      ),
    );
    expect(text, l.awayPlanningIndeterminatePending);
  });
}
