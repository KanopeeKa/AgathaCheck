import 'package:flutter/material.dart';

import '../../../../../core/utils/calendar_date.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/health_entry.dart';
import '../health_entry_type_labels.dart';

/// Live preview for the desktop health entry form.
class HealthEntryFormPreviewCard extends StatelessWidget {
  const HealthEntryFormPreviewCard({
    super.key,
    required this.name,
    required this.type,
    required this.dosage,
    this.dueDate,
    this.completedOn,
    this.petNames = const [],
  });

  final String name;
  final HealthEntryType type;
  final String dosage;
  final DateTime? dueDate;
  final DateTime? completedOn;
  final List<String> petNames;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final displayName = name.trim().isEmpty ? l.entryName : name.trim();
    final typeLabel = healthEntryTypeLabel(l, type);

    return Card(
      key: const Key('health_entry_form_preview_card'),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.event_note_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              displayName,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              typeLabel,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (dosage.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                dosage.trim(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            if (petNames.isNotEmpty)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: petNames
                    .map(
                      (pet) => Chip(
                        avatar: const Icon(Icons.pets, size: 18),
                        label: Text(pet),
                      ),
                    )
                    .toList(),
              ),
            if (dueDate != null) ...[
              const SizedBox(height: 12),
              _PreviewRow(
                icon: Icons.event,
                label: l.dueDate,
                value: formatCalendarDateDisplay(calendarDateOnly(dueDate!)),
              ),
            ],
            if (completedOn != null) ...[
              const SizedBox(height: 8),
              _PreviewRow(
                icon: Icons.check_circle_outline,
                label: l.completedOn,
                value: formatCalendarDateDisplay(
                  calendarDateOnly(completedOn!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text('$label: $value', style: theme.textTheme.bodyMedium),
        ),
      ],
    );
  }
}
