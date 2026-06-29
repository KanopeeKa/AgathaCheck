import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/health_entry_type_labels.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

class PetEventEntryList extends StatelessWidget {
  const PetEventEntryList({
    super.key,
    required this.entries,
    required this.petId,
    required this.onEntryTap,
  });

  final List<HealthEntry> entries;
  final String petId;
  final void Function(HealthEntry entry) onEntryTap;

  static IconData iconForType(HealthEntryType type) {
    switch (type) {
      case HealthEntryType.medication:
        return Icons.medication_outlined;
      case HealthEntryType.preventive:
        return Icons.shield_outlined;
      case HealthEntryType.vetVisit:
        return Icons.local_hospital_outlined;
      case HealthEntryType.procedure:
        return Icons.more_horiz_outlined;
      case HealthEntryType.familyEvent:
        return Icons.event_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;
    final dateFormat = DateFormat.yMMMd();

    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          l.noEntriesYet,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final detail = entry.dosage.trim().isEmpty
            ? healthEntryTypeLabel(l, entry.type)
            : '${healthEntryTypeLabel(l, entry.type)} · ${entry.dosage}';

        final Widget statusLine;
        if (entry.isCompleted) {
          statusLine = Text(
            l.completed,
            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary),
          );
        } else if (entry.isOverdue && entry.nextDueDate != null) {
          statusLine = Text(
            '${l.overdue} · ${dateFormat.format(entry.nextDueDate!)}',
            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
          );
        } else if (entry.completedOn != null) {
          statusLine = Text(
            '${l.completedOn}: ${dateFormat.format(entry.completedOn!)}',
            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary),
          );
        } else if (entry.nextDueDate != null) {
          statusLine = Text(
            dateFormat.format(entry.nextDueDate!),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          );
        } else {
          statusLine = Text(
            l.notSet,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          );
        }

        return ListTile(
          leading: Icon(
            iconForType(entry.type),
            color: entry.isOverdue ? colorScheme.error : colorScheme.primary,
          ),
          title: Text(entry.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(detail), statusLine],
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onEntryTap(entry),
        );
      },
    );
  }
}
