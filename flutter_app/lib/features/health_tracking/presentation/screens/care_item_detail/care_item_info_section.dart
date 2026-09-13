import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_profile/domain/services/care_family_inference.dart';
import '../../../../pet_profile/presentation/widgets/care_family_icon.dart';
import '../../../../pet_profile/presentation/widgets/care_family_labels.dart';
import '../../../domain/entities/health_entry.dart';
import '../../widgets/pet_event_lifecycle.dart';

/// Care item identity: family, name, recurrence in plain language, notes.
class CareItemInfoSection extends StatelessWidget {
  const CareItemInfoSection({
    super.key,
    required this.entry,
    required this.muted,
  });

  final HealthEntry entry;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = muted ? colorScheme.onSurfaceVariant : null;
    final family = entry.careFamily ?? inferCareFamily(entry);

    return Column(
      key: const Key('care_item_info_section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CareFamilyIcon.forEntry(entry, showChip: false),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      entry.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    careFamilyLabel(l, family),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
        const SizedBox(height: 16),
        Text(
          l.notes,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          entry.notes.isNotEmpty ? entry.notes : l.notSet,
          style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
        ),
      ],
    );
  }
}
