import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_history_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/health_entry_status.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/health_entry_type_labels.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import 'manage_events_filters.dart';

/// Compact two-line event row with date on the right and chevron.
class EventListCard extends StatelessWidget {
  const EventListCard({
    super.key,
    required this.entry,
    required this.history,
    required this.petId,
  });

  final HealthEntry entry;
  final List<HealthHistoryEntry> history;
  final String petId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    final detail = entry.dosage.trim().isEmpty
        ? healthEntryTypeLabel(l, entry.type)
        : '${healthEntryTypeLabel(l, entry.type)} · ${entry.dosage}';
    final statusLine = formatManageEventStatusLine(entry, l, history);
    final statusColor = isCurrentOccurrenceSkipped(entry, history)
        ? colorScheme.onSurfaceVariant
        : healthEntryStatusColor(entry, colorScheme);

    return Semantics(
      button: true,
      label: '${entry.name}, $detail, $statusLine',
      child: InkWell(
        key: Key('event_list_card_${entry.id}'),
        onTap: () => context.go('/pet/$petId/events/${entry.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    statusLine,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
