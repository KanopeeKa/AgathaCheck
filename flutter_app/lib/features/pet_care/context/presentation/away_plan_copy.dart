import '../../../../l10n/app_localizations.dart';
import '../domain/entities/away_plan_readiness.dart';
import '../domain/entities/care_period_coverage.dart';
import '../domain/entities/planned_absence_pet_carer.dart';

class AwayPlanCopy {
  const AwayPlanCopy._();

  static const Map<CarePeriodCoverageState, String> _careCoverageCopyKeys = {
    CarePeriodCoverageState.nothingScheduled:
        'careContextCoverageNothingScheduled',
    CarePeriodCoverageState.allCompleted: 'careContextCoverageAllCompleted',
    CarePeriodCoverageState.noUnresolvedItems:
        'careContextCoverageNoUnresolved',
    CarePeriodCoverageState.hasItemsToReview:
        'careContextCoverageHasItemsToReview',
    CarePeriodCoverageState.indeterminate: 'careContextCoverageIndeterminate',
  };

  /// Per-pet care coverage sentence for the per-pet handover PDF — built from
  /// this pet's own [CarePeriodCoverageResult], never from [AwayPlanReadiness]
  /// aggregates. Those pick the least-reassuring state across every pet on
  /// the absence (D-AWAY-002), which would misrepresent a single pet.
  static String petCareCoverageSummary(
    AppLocalizations l,
    CarePeriodCoverageResult coverage,
  ) {
    final state = coverage.coverage.coverageState;
    final fact = CareCoverageFact(
      policyVersion: coverage.coverage.policyVersion,
      coverageState: state.wireValue,
      reasonCodes: coverage.coverage.reasonCodes,
      reassuranceAvailable: coverage.coverage.reassuranceAvailable,
      copyKey:
          _careCoverageCopyKeys[state] ?? 'careContextCoverageIndeterminate',
      copyCount: state == CarePeriodCoverageState.hasItemsToReview
          ? coverage.items.where((item) => item.isPending).length
          : null,
    );
    return careCoverageSummary(l, fact);
  }

  static String carerCoverageSummary(
    AppLocalizations l,
    CarerCoverageFact fact,
  ) {
    return switch (fact.copyKey) {
      'awayPlanningCarerCoverageAllHaveCarers' =>
        l.awayPlanningCarerCoverageAllHaveCarers,
      'awayPlanningCarerCoverageSomeHaveCarers' =>
        l.awayPlanningCarerCoverageSomeHaveCarers(
          fact.petsWithCarer,
          fact.petsTotal,
        ),
      'awayPlanningCarerCoverageNoneHaveCarers' =>
        l.awayPlanningCarerCoverageNoneHaveCarers,
      _ => l.awayPlanningCarerCoverageNoneHaveCarers,
    };
  }

  static String careCoverageSummary(AppLocalizations l, CareCoverageFact fact) {
    return switch (fact.copyKey) {
      'careContextCoverageNothingScheduled' =>
        l.careContextCoverageNothingScheduled,
      'careContextCoverageAllCompleted' => l.careContextCoverageAllCompleted,
      'careContextCoverageNoUnresolved' => l.careContextCoverageNoUnresolved,
      'careContextCoverageHasItemsToReview' =>
        l.careContextCoverageHasItemsToReview(fact.copyCount ?? 0),
      'careContextCoverageIndeterminate' => l.careContextCoverageIndeterminate,
      _ => l.careContextCoverageIndeterminate,
    };
  }

  /// Pet-scoped carer coverage sentence for the per-pet handover PDF.
  /// Deliberately does not reuse [carerCoverageSummary]'s copy keys — those
  /// are absence-wide ("all/some/none of the pets…") and would misstate a
  /// single pet's coverage (D-AWAY-014a).
  static String petCarerCoverageSummary(
    AppLocalizations l,
    PlannedAbsencePetCarer carer,
    String petName,
  ) {
    if (carer.isCarerUnavailable) {
      return l.awayPlanningPetCarerCoverageRemoved(petName);
    }
    if (!carer.hasCarer) {
      return l.awayPlanningPetCarerCoverageUnassigned(petName);
    }
    return l.awayPlanningPetCarerCoverageAssigned(petName);
  }

  static String petCarerLabel(
    AppLocalizations l,
    PlannedAbsencePetCarer carer,
  ) {
    if (carer.isCarerUnavailable) return l.awayPlanningCarerRemoved;
    if (!carer.hasCarer) return l.awayPlanningCarerUnset;
    return switch (carer.carerKind) {
      'shared_user' => l.awayPlanningCarerSharedAccess(
        carer.carerName ?? l.awayPlanningCarerSharedUserFallback,
      ),
      'note_only' => () {
        final name = carer.carerName ?? '';
        final note = (carer.carerNote ?? '').trim();
        if (note.isNotEmpty) {
          return l.awayPlanningCarerNoteOnlyWithNote(name, note);
        }
        return l.awayPlanningCarerNoteOnly(name);
      }(),
      _ => l.awayPlanningCarerUnset,
    };
  }

  static List<String> handoverContactLines(
    AppLocalizations l,
    List<Map<String, dynamic>> relationships,
  ) {
    const kinds = ['primary_vet', 'out_of_hours_vet', 'emergency_contact'];
    final lines = <String>[];
    for (final kind in kinds) {
      for (final row in relationships) {
        if (row['relationship_kind'] != kind) continue;
        if (row['active'] == false) continue;
        final contact = row['contact'] as Map<String, dynamic>?;
        if (contact == null) continue;
        if (contact['inactive_at'] != null) continue;
        final name = contact['name'] as String? ?? '';
        if (name.isEmpty) continue;
        final roleLabel = switch (kind) {
          'primary_vet' => l.awayPlanningHandoverPrimaryVet,
          'out_of_hours_vet' => l.awayPlanningHandoverOutOfHoursVet,
          'emergency_contact' => l.awayPlanningHandoverEmergencyContact,
          _ => kind,
        };
        final phone = contact['phone'] as String?;
        final detail = phone != null && phone.isNotEmpty
            ? '$name · $phone'
            : name;
        lines.add(l.awayPlanningHandoverContactLine(roleLabel, detail));
      }
    }
    return lines;
  }
}
