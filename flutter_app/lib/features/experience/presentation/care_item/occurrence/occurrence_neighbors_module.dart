import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:pet_profile_app/core/providers/analytics_providers.dart';
import 'package:pet_profile_app/core/router/shell_return_navigation.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/features/experience/presentation/care_item/care_item_occurrence_status_pill.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

/// Block 4 — chronological previous/next neighbours (CARE-ITEM-R-020).
class OccurrenceNeighborsModule extends ConsumerWidget {
  const OccurrenceNeighborsModule({
    super.key,
    required this.petId,
    required this.entryId,
    required this.detail,
  });

  final String petId;
  final String entryId;
  final OccurrenceDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final prev = detail.previousOccurrence;
    final next = detail.nextOccurrence;

    return Semantics(
      identifier: 'occurrence_neighbors_section',
      container: true,
      child: CareItemModule(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
            final stackVertically =
                width < 360 ||
                MediaQuery.textScalerOf(context).scale(14) >= 18.2;

            final previousSlot = _NeighborSlot(
              label: l.occurrenceNeighborPreviousLabel,
              emptyCopy: l.occurrenceNeighborNonePrevious,
              neighbor: prev,
              semanticsId: 'occurrence_neighbor_previous',
              chevron: Icons.chevron_left,
              onOpen: prev == null
                  ? null
                  : () => _openNeighbor(
                      ref,
                      context,
                      direction: 'previous',
                      occurrenceId: prev.id,
                    ),
            );
            final nextSlot = _NeighborSlot(
              label: l.occurrenceNeighborNextLabel,
              emptyCopy: l.occurrenceNeighborNoneNext,
              neighbor: next,
              semanticsId: 'occurrence_neighbor_next',
              chevron: Icons.chevron_right,
              onOpen: next == null
                  ? null
                  : () => _openNeighbor(
                      ref,
                      context,
                      direction: 'next',
                      occurrenceId: next.id,
                    ),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.occurrenceNeighborsTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                if (stackVertically) ...[
                  previousSlot,
                  const SizedBox(height: 12),
                  nextSlot,
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: previousSlot),
                      const SizedBox(width: 12),
                      Expanded(child: nextSlot),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openNeighbor(
    WidgetRef ref,
    BuildContext context, {
    required String direction,
    required String occurrenceId,
  }) {
    ref.read(analyticsServiceProvider).capture('occurrence_neighbor_opened', {
      'direction': direction,
    });
    replaceOccurrenceScreen(
      context,
      petId: petId,
      entryId: entryId,
      occurrenceId: occurrenceId,
      source: 'neighbor',
    );
  }
}

class _NeighborSlot extends StatelessWidget {
  const _NeighborSlot({
    required this.label,
    required this.emptyCopy,
    required this.neighbor,
    required this.semanticsId,
    required this.chevron,
    required this.onOpen,
  });

  final String label;
  final String emptyCopy;
  final OccurrenceNeighborSummary? neighbor;
  final String semanticsId;
  final IconData chevron;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (neighbor == null) {
      return Semantics(
        identifier: semanticsId,
        container: true,
        label: '$label. $emptyCopy',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(
              emptyCopy,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final when = _formatWhen(context, l, neighbor!);
    final status = careOccurrenceStatusFromApi(neighbor!.occurrenceStatus);
    final pill = openOccurrencePillStyle(l, status);

    return Semantics(
      identifier: semanticsId,
      button: onOpen != null,
      label: '$label, $when, ${pill.label}',
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onOpen,
                icon: Icon(chevron),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.labelMedium),
                    const SizedBox(height: 4),
                    Text(when, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    CareItemOccurrenceStatusPill(pill: pill),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatWhen(
    BuildContext context,
    AppLocalizations l,
    OccurrenceNeighborSummary neighbor,
  ) {
    final locale = Localizations.localeOf(context).toString();
    final dateStr = DateFormat.yMMMd(locale).format(neighbor.scheduledDate);
    final time = neighbor.scheduledTime;
    if (time == null || time.isEmpty) return dateStr;
    final parts = time.split(':');
    if (parts.length < 2) return l.occurrenceDateAtTime(dateStr, time);
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final formattedTime = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay(hour: hour, minute: minute));
    return l.occurrenceDateAtTime(dateStr, formattedTime);
  }
}
