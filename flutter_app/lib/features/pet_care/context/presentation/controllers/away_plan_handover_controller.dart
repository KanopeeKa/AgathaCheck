import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/calendar_date.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_profile/data/services/pdf_saver.dart' as pdf_saver;
import '../../data/services/away_plan_handover_service.dart';
import '../../domain/entities/away_plan_readiness.dart';
import '../../domain/entities/care_period_coverage.dart';
import '../../domain/entities/planned_absence.dart';
import '../../domain/entities/planned_absence_pet_carer.dart';
import '../away_plan_copy.dart';
import '../away_plan_schedule_copy.dart';
import '../providers/care_context_providers.dart';

class AwayPlanHandoverController {
  AwayPlanHandoverController(this.ref);

  final WidgetRef ref;

  Future<void> downloadHandover({
    required BuildContext context,
    required PlannedAbsence absence,
    required AwayPlanReadiness readiness,
    required Map<String, String> petNamesById,
  }) async {
    final l = AppLocalizations.of(context)!;
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final repository = ref.read(careContextRepositoryProvider);
      final orderedPetIds = [...absence.petIds]..sort();
      final petSections = <AwayPlanHandoverPetSection>[];

      for (final petId in orderedPetIds) {
        final coverage = await repository.getCarePeriodCoverage(
          petId: petId,
          startsOn: absence.startsOn,
          endsOn: absence.endsOn,
        );
        final carer = absence.petCarers.firstWhere(
          (row) => row.petId == petId,
          orElse: () => PlannedAbsencePetCarer(petId: petId),
        );
        petSections.add(
          AwayPlanHandoverPetSection(
            petName: petNamesById[petId] ?? petId,
            carerLabel: AwayPlanCopy.petCarerLabel(l, carer),
            routineLines: coverage.routineItems
                .map(
                  (item) =>
                      '${AwayPlanScheduleCopy.routineRowTitle(item)} — ${AwayPlanScheduleCopy.routineRowSubtitle(l, item)}',
                )
                .toList(growable: false),
            datedLines: coverage.datedItems
                .map(
                  (item) =>
                      '${item.name} — ${AwayPlanScheduleCopy.datedRowStatus(l, item)}',
                )
                .toList(growable: false),
            indeterminateLines: coverage.uncertainties
                .map(
                  (item) =>
                      '${item.name.isNotEmpty ? item.name : item.healthEntryId} — ${AwayPlanScheduleCopy.indeterminateRowSubtitle(l, item)}',
                )
                .toList(growable: false),
          ),
        );
      }

      final start = parseCalendarDate(absence.startsOn);
      final end = parseCalendarDate(absence.endsOn);
      final dateRangeLabel = start != null && end != null
          ? l.careContextAwayPreviewDateRange(
              formatCalendarDateDisplay(start),
              formatCalendarDateDisplay(end),
            )
          : '${absence.startsOn} – ${absence.endsOn}';
      final petNames = orderedPetIds
          .map((petId) => petNamesById[petId] ?? petId)
          .join(', ');

      final document = AwayPlanHandoverDocument(
        title: l.careContextAwayPlanTitle,
        dateRangeLabel: dateRangeLabel,
        petNamesLabel: petNames,
        carerCoverageSummary: AwayPlanCopy.carerCoverageSummary(l, readiness.carerCoverage),
        careCoverageSummary: AwayPlanCopy.careCoverageSummary(l, readiness.careCoverage),
        handoverNote: absence.handoverNote,
        petSections: petSections,
      );

      final service = AwayPlanHandoverService();
      final pdfBytes = await service.generateHandoverPdf(document: document, l: l);
      await repository.recordHandoverDownload(absence.id);

      if (context.mounted) {
        Navigator.of(context).pop();
      }

      final filename =
          'away_plan_${absence.startsOn}_${absence.endsOn}.pdf'.replaceAll(':', '-');
      await pdf_saver.savePdf(pdfBytes, filename);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.reportGenerated)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.pdfExportFailed('$e'))),
        );
      }
    }
  }
}
