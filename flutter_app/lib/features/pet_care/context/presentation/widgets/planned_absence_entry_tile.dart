import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_color_tokens.dart';
import '../../../../../l10n/app_localizations.dart';

/// Pull-only entry point for the away-planning preview flow.
class PlannedAbsenceEntryTile extends StatelessWidget {
  const PlannedAbsenceEntryTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: '${l.careContextAwayEntryTitle}. ${l.careContextAwayEntryBody}',
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          key: const Key('planned_absence_entry_tile'),
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/pc/away'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColorTokens.petCareLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.event_busy_outlined,
                      color: AppColorTokens.petCareCarePrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.careContextAwayEntryTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColorTokens.heading,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.careContextAwayEntryBody,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
