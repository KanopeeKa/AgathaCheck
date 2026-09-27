import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/health_entry.dart';
import '../../widgets/pet_event_lifecycle.dart';

/// Schedule summary (spec §Schedule) — rhythm, reminder; controls live in Edit.
class CareItemScheduleSection extends StatelessWidget {
  const CareItemScheduleSection({
    super.key,
    required this.entry,
    required this.petId,
    required this.muted,
  });

  final HealthEntry entry;
  final String petId;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = muted ? colorScheme.onSurfaceVariant : null;

    return Column(
      key: const Key('care_item_schedule_section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l.careItemScheduleTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          formatRecurrenceSummary(l, entry),
          style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
        ),
        const SizedBox(height: 4),
        Text(
          formatRemindSummary(l, entry),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        if (!muted) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('care_item_edit_schedule'),
              onPressed: () => context.push(healthEntryEditRoute(entry, petId)),
              child: Text(l.careItemEditSchedule),
            ),
          ),
        ],
      ],
    );
  }
}
