import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../care_item/care_item.dart';
import '../../../../health_tracking/domain/entities/health_entry.dart';
import '../care_surface/care_collection_inset_list.dart';
import '../care_surface/care_surface_tokens.dart';

typedef CareAgendaRowBuilder = Widget Function(CareAgendaRow<HealthEntry> row);

String careTimeGroupLabel(AppLocalizations l, CareTimeGroup group) =>
    switch (group) {
      CareTimeGroup.morning => l.careAgendaMorning,
      CareTimeGroup.afternoon => l.careAgendaAfternoon,
      CareTimeGroup.evening => l.careAgendaEvening,
      CareTimeGroup.anytime => l.careAgendaAnytime,
    };

/// The agenda (D-CIE-025, UIR-4/5/17) as inset collection items: Today
/// (overdue, time groups, done today), Due soon, and Upcoming (collapsed,
/// with a count). Shared by the dashboard, the pet profile and All care.
List<CareCollectionInsetItem> buildCareAgendaInsetItems({
  required BuildContext context,
  required CareAgenda<HealthEntry> agenda,
  required CareAgendaRowBuilder rowBuilder,
  required bool upcomingExpanded,
  required VoidCallback onToggleUpcoming,
}) {
  final l = AppLocalizations.of(context)!;
  final items = <CareCollectionInsetItem>[];

  void header(String key, String text, {bool level2 = false}) {
    items.add(
      CareCollectionInsetItem(
        showDividerBefore: items.isNotEmpty,
        child: _AgendaHeader(key: Key(key), text: text, level2: level2),
      ),
    );
  }

  void rows(Iterable<CareAgendaRow<HealthEntry>> list) {
    for (final row in list) {
      items.add(
        CareCollectionInsetItem(
          showDividerBefore: true,
          child: rowBuilder(row),
        ),
      );
    }
  }

  header('care_agenda_today', l.careAgendaToday);
  if (agenda.overdue.isEmpty && agenda.today.isEmpty) {
    items.add(
      CareCollectionInsetItem(
        showDividerBefore: true,
        child: _AgendaLine(
          key: const Key('care_agenda_nothing_today'),
          text: l.careAgendaNothingDueToday,
        ),
      ),
    );
  }
  rows(agenda.overdue);
  if (agenda.showTimeGroupHeadings) {
    for (final entry in agenda.today.entries) {
      header(
        'care_agenda_group_${entry.key.name}',
        careTimeGroupLabel(l, entry.key),
        level2: true,
      );
      rows(entry.value);
    }
  } else if (agenda.today.isNotEmpty) {
    header('care_agenda_todays_list', l.careAgendaTodaysList, level2: true);
    rows(agenda.today.values.expand((r) => r));
  }
  rows(agenda.doneToday);

  if (agenda.dueSoon.isNotEmpty) {
    header('care_agenda_due_soon', l.careAgendaDueSoon);
    rows(agenda.dueSoon);
  }

  if (agenda.upcoming.isNotEmpty) {
    items.add(
      CareCollectionInsetItem(
        showDividerBefore: true,
        child: _UpcomingToggle(
          count: agenda.upcoming.length,
          expanded: upcomingExpanded,
          onToggle: onToggleUpcoming,
        ),
      ),
    );
    if (upcomingExpanded) rows(agenda.upcoming);
  }
  return items;
}

/// Dashboard orientation line (UIR-17).
String careAgendaOrientation(AppLocalizations l, CareAgenda<Object?> agenda) {
  if (agenda.overdueCount == 0 && agenda.dueTodayCount == 0) {
    return l.careAgendaNothingDueToday;
  }
  return l.careAgendaOrientation(agenda.overdueCount, agenda.dueTodayCount);
}

class _AgendaHeader extends StatelessWidget {
  const _AgendaHeader({super.key, required this.text, this.level2 = false});

  final String text;
  final bool level2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: CareSurfaceTokens.collectionHeaderPadding,
        child: Text(
          text,
          style:
              (level2 ? theme.textTheme.labelLarge : theme.textTheme.titleSmall)
                  ?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: level2 ? theme.colorScheme.onSurfaceVariant : null,
                  ),
        ),
      ),
    );
  }
}

class _AgendaLine extends StatelessWidget {
  const _AgendaLine({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: CareSurfaceTokens.collectionInsetRowPadding,
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _UpcomingToggle extends StatelessWidget {
  const _UpcomingToggle({
    required this.count,
    required this.expanded,
    required this.onToggle,
  });

  final int count;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      button: true,
      expanded: expanded,
      hint: expanded ? l.careAgendaHideUpcoming : l.careAgendaShowUpcoming,
      child: InkWell(
        key: const Key('care_agenda_upcoming'),
        onTap: onToggle,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: CareSurfaceTokens.collectionHeaderPadding,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.careAgendaUpcoming(count),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ExcludeSemantics(
                  child: Icon(expanded ? Icons.expand_less : Icons.expand_more),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
