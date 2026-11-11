import 'package:flutter/material.dart';

import '../../../../../core/utils/calendar_date.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../care_item/care_item.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import '../care_agenda/care_coordination_banner.dart';
import '../care_surface/care_collection_inset_list.dart';
import '../care_surface/care_surface_tokens.dart';

typedef CareListCardBuilder = Widget Function(
  HealthEntry entry, {
  required bool todaySection,
});

List<CareCollectionInsetItem> buildCareListInsetItems({
  required BuildContext context,
  required CareListPartition<HealthEntry> partition,
  required CareListCardBuilder cardBuilder,
  required bool upcomingExpanded,
  required VoidCallback onToggleUpcoming,
  Map<String, String>? petNames,
  void Function(String petId)? onOpenPet,
  Duration elapsed = Duration.zero,
}) {
  final l = AppLocalizations.of(context)!;
  final items = <CareCollectionInsetItem>[];

  void header(
    String key,
    String text, {
    bool level2 = false,
    String? semanticsIdentifier,
  }) {
    items.add(
      CareCollectionInsetItem(
        showDividerBefore: items.isNotEmpty,
        child: _CareListHeader(
          key: Key(key),
          text: text,
          level2: level2,
          semanticsIdentifier: semanticsIdentifier ?? key,
        ),
      ),
    );
  }

  void card(HealthEntry entry, {required bool todaySection}) {
    items.add(
      CareCollectionInsetItem(
        showDividerBefore: true,
        child: cardBuilder(entry, todaySection: todaySection),
      ),
    );
  }

  void upcomingWithDateHeaders(List<HealthEntry> entries) {
    final multiPet =
        petNames != null && petNames.length > 1 && onOpenPet != null;
    final rows = <CareAgendaRow<HealthEntry>>[];
    for (final entry in entries) {
      final row = careListUpcomingRow(entry, entry.schedule!, elapsed: elapsed);
      if (row != null) rows.add(row);
    }
    for (final group in groupAgendaRowsByDueDate(rows)) {
      if (showSameDayDateHeader(group)) {
        header(
          'care_list_date_${group.dateKey}',
          formatCalendarDateDisplay(group.date),
          level2: true,
        );
      }
      if (multiPet && showCoordinationBanner(group, (entry) => entry.petId)) {
        final ids = coordinationPetIds(group, (entry) => entry.petId);
        final names = {
          for (final id in ids)
            if (petNames.containsKey(id)) id: petNames[id]!,
        };
        if (names.length >= 2) {
          items.add(
            CareCollectionInsetItem(
              showDividerBefore: true,
              child: CareCoordinationBanner(
                date: group.date,
                dateKey: group.dateKey,
                petNames: names,
                onOpenPet: onOpenPet,
              ),
            ),
          );
        }
      }
      for (final row in group.rows) {
        card(row.item, todaySection: false);
      }
    }
  }

  header('care_list_today', l.careAgendaToday);
  if (partition.today.isEmpty) {
    items.add(
      CareCollectionInsetItem(
        showDividerBefore: true,
        child: _CareListLine(
          key: const Key('care_list_nothing_today'),
          text: l.careAgendaNothingDueToday,
        ),
      ),
    );
  } else {
    for (final entry in partition.today) {
      card(entry, todaySection: true);
    }
  }

  if (partition.upcoming.isNotEmpty) {
    items.add(
      CareCollectionInsetItem(
        showDividerBefore: true,
        child: _UpcomingToggle(
          count: partition.upcoming.length,
          expanded: upcomingExpanded,
          onToggle: onToggleUpcoming,
        ),
      ),
    );
    if (upcomingExpanded) {
      upcomingWithDateHeaders(partition.upcoming);
    }
  }

  return items;
}

class _CareListHeader extends StatelessWidget {
  const _CareListHeader({
    super.key,
    required this.text,
    this.level2 = false,
    this.semanticsIdentifier,
  });

  final String text;
  final bool level2;
  final String? semanticsIdentifier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      identifier: semanticsIdentifier,
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

class _CareListLine extends StatelessWidget {
  const _CareListLine({super.key, required this.text});

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
      identifier: 'care_list_upcoming',
      hint: expanded ? l.careAgendaHideUpcoming : l.careAgendaShowUpcoming,
      child: InkWell(
        key: const Key('care_list_upcoming'),
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
