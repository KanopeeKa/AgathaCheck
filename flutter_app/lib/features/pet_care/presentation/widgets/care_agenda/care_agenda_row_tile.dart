import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../care_item/care_item.dart';
import '../../../../health_tracking/domain/entities/health_entry.dart';
import '../../../../health_tracking/presentation/widgets/health_entry_status.dart';
import '../../../../health_tracking/presentation/widgets/pet_event_lifecycle.dart';
import '../../../../pet_profile/domain/services/care_family_inference.dart';
import '../../../../pet_profile/presentation/widgets/care_family_icon.dart';
import '../../../../pet_profile/presentation/widgets/care_family_labels.dart';
import '../care_surface/care_action_row.dart';

/// Status words and chips for one agenda row (D-CIE-024, §18.6.3).
String careAgendaStatusText(
  CareAgendaRow<HealthEntry> row,
  AppLocalizations l, {
  required String Function(DateTime date) formatDate,
}) {
  if (row.section == CareAgendaSection.doneToday) {
    return l.careDoneAt(row.schedule.lastDone?.time ?? '');
  }
  if (row.isStack) return l.careStackCount(row.stackCount);
  final occ = row.occurrence;
  if (occ == null) return '';
  final word = switch (row.status) {
    CareOccurrenceStatus.overdue => l.urgencyOverdue,
    CareOccurrenceStatus.notRecorded => l.careStatusNotRecorded,
    CareOccurrenceStatus.due => l.careStatusDue,
    _ => l.careStatusComingUp,
  };
  final isToday = occ.date == row.schedule.asOf.date;
  final when = [if (!isToday) formatDate(occ.date), ?occ.time].join(' · ');
  return when.isEmpty ? word : '$word · $when';
}

HealthEntryStatusTreatment careAgendaStatusTreatment(
  CareAgendaRow<HealthEntry> row,
  ColorScheme colorScheme,
) {
  if (row.section == CareAgendaSection.doneToday) {
    return completedStatusTreatment();
  }
  if (row.isStack) return notRecordedStatusTreatment();
  return switch (row.status) {
    CareOccurrenceStatus.overdue => overdueStatusTreatment(colorScheme),
    CareOccurrenceStatus.notRecorded => notRecordedStatusTreatment(),
    CareOccurrenceStatus.due => dueTodayStatusTreatment(),
    _ => comingUpStatusTreatment(colorScheme),
  };
}

/// One agenda row (R3): the row opens its occurrence — or the care item for
/// a stack or a done-today row — and carries one trailing Done (§18.6.3).
class CareAgendaRowTile extends StatelessWidget {
  const CareAgendaRowTile({
    super.key,
    required this.row,
    required this.onOpen,
    this.onDone,
    this.petName,
    this.inset = true,
  });

  final CareAgendaRow<HealthEntry> row;

  /// Opens the occurrence screen, or the Care Item view for a stack.
  final VoidCallback onOpen;

  /// Done (§18.6.1); null hides the tick (done-today rows).
  final VoidCallback? onDone;

  /// Shown on the dashboard (all pets) only.
  final String? petName;
  final bool inset;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final entry = row.item;
    final status = careAgendaStatusText(
      row,
      l,
      formatDate: formatHealthEntryStatusDate,
    );
    final family = entry.careFamily ?? inferCareFamily(entry);
    final subtitle = [
      ?petName,
      careFamilyLabel(l, family),
      formatRecurrenceSummary(l, entry),
    ].join(' · ');
    final opensItem = row.isStack || row.section == CareAgendaSection.doneToday;
    final label = [?petName, entry.name, status].join(', ');
    final done = row.section == CareAgendaSection.doneToday ? null : onDone;

    return CareActionRow(
      key: row.isStack
          ? Key('care_agenda_stack_${entry.id}')
          : Key('pet_care_action_${entry.id}'),
      inset: inset,
      title: entry.name,
      subtitle: subtitle,
      statusLabel: status,
      statusTreatment: careAgendaStatusTreatment(row, colorScheme),
      semanticLabel:
          '$label. ${opensItem ? l.careRowOpensItem : l.careRowOpensDate}',
      leading: CareFamilyIcon.forEntry(entry),
      onPressed: done,
      markDoneKey: Key('pet_care_action_done_${entry.id}'),
      markDoneSemanticLabel: l.careMarkDoneLabel(entry.name),
      markDoneSemanticsIdentifier: 'pet_care_action_done_${entry.id}',
      onTap: onOpen,
    );
  }
}
