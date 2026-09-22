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

  /// Shared by the full-plan and per-pet exports so schedule rendering and
  /// coverage copy cannot drift between them (D-AWAY-014a/§5.3).
  ///
  /// [petFilter] null → full plan: every pet, absence-wide [readiness]
  /// summaries. [petFilter] set → single pet only, with pet-scoped carer and
  /// care coverage summaries built from that pet's own facts, never from
  /// [readiness].
  Future<AwayPlanHandoverDocument> _buildDocument({
    required BuildContext context,
    required PlannedAbsence absence,
    required Map<String, String> petNamesById,
    String? petFilter,
    AwayPlanReadiness? readiness,
  }) async {
    final l = AppLocalizations.of(context)!;
    final repository = ref.read(careContextRepositoryProvider);
    final allPetIds = [...absence.petIds]..sort();
    final targetPetIds = petFilter != null ? [petFilter] : allPetIds;

    final petSections = <AwayPlanHandoverPetSection>[];
    var carerCoverageSummary = '';
    var careCoverageSummary = '';

    for (final petId in targetPetIds) {
      final coverage = await repository.getCarePeriodCoverage(
        petId: petId,
        startsOn: absence.startsOn,
        endsOn: absence.endsOn,
      );
      final carer = absence.petCarers.firstWhere(
        (row) => row.petId == petId,
        orElse: () => PlannedAbsencePetCarer(petId: petId),
      );
      final petName = petNamesById[petId] ?? petId;

      if (petFilter != null) {
        carerCoverageSummary = AwayPlanCopy.petCarerCoverageSummary(
          l,
          carer,
          petName,
        );
        careCoverageSummary = AwayPlanCopy.petCareCoverageSummary(l, coverage);
      }

      petSections.add(
        AwayPlanHandoverPetSection(
          petName: petName,
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
          petNote: carer.petNote,
        ),
      );
    }

    if (petFilter == null && readiness != null) {
      carerCoverageSummary = AwayPlanCopy.carerCoverageSummary(
        l,
        readiness.carerCoverage,
      );
      careCoverageSummary = AwayPlanCopy.careCoverageSummary(
        l,
        readiness.careCoverage,
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
    // Trip pet list is always the full roster, even on a per-pet export —
    // it's context, not a disclosure risk (§5.1).
    final petNamesLabel = allPetIds
        .map((petId) => petNamesById[petId] ?? petId)
        .join(', ');

    return AwayPlanHandoverDocument(
      title: l.careContextAwayPlanTitle,
      dateRangeLabel: dateRangeLabel,
      petNamesLabel: petNamesLabel,
      carerCoverageSummary: carerCoverageSummary,
      careCoverageSummary: careCoverageSummary,
      handoverNote: absence.handoverNote,
      handoverNoteSectionTitle: petFilter != null
          ? l.awayPlanningHandoverTripNotesTitle
          : null,
      petSections: petSections,
    );
  }

  Future<void> downloadHandover({
    required BuildContext context,
    required PlannedAbsence absence,
    required AwayPlanReadiness readiness,
    required Map<String, String> petNamesById,
  }) async {
    final l = AppLocalizations.of(context)!;
    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final repository = ref.read(careContextRepositoryProvider);
      final document = await _buildDocument(
        context: context,
        absence: absence,
        petNamesById: petNamesById,
        readiness: readiness,
      );

      final service = AwayPlanHandoverService();
      final pdfBytes = await service.generateHandoverPdf(
        document: document,
        l: l,
      );
      await repository.recordHandoverDownload(absence.id);

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      final filename = 'away_plan_${absence.startsOn}_${absence.endsOn}.pdf'
          .replaceAll(':', '-');
      await pdf_saver.savePdf(pdfBytes, filename);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.reportGenerated)));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.pdfExportFailed('$e'))));
      }
    }
  }

  /// Privacy-trimmed handover for a single pet — the sole channel a
  /// `note_only` carer has (D-AWAY-004, D-AWAY-014a). Does not call
  /// `recordHandoverDownload`: `last_handover_downloaded_at` tracks the
  /// full-plan export only (D-AWAY-014b).
  Future<void> downloadPetHandover({
    required BuildContext context,
    required PlannedAbsence absence,
    required String petId,
    required Map<String, String> petNamesById,
  }) async {
    final l = AppLocalizations.of(context)!;
    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final document = await _buildDocument(
        context: context,
        absence: absence,
        petNamesById: petNamesById,
        petFilter: petId,
      );

      final service = AwayPlanHandoverService();
      final pdfBytes = await service.generateHandoverPdf(
        document: document,
        l: l,
      );

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      final petSlug = _slugifyPetName(petNamesById[petId] ?? petId);
      final filename =
          'away_plan_${petSlug}_${absence.startsOn}_${absence.endsOn}.pdf'
              .replaceAll(':', '-');
      await pdf_saver.savePdf(pdfBytes, filename);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.reportGenerated)));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.pdfExportFailed('$e'))));
      }
    }
  }

  String _slugifyPetName(String value) {
    final slug = value
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'pet' : slug;
  }
}
