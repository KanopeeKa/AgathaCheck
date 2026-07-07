import 'package:flutter/material.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/health_entry_status.dart';
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
        final statusColor = healthEntryStatusColor(entry, colorScheme);
        final statusLine = formatHealthEntryStatusLine(entry, l);

        return ListTile(
          leading: Icon(iconForType(entry.type), color: statusColor),
          title: Text(entry.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(detail),
              Text(
                statusLine,
                style: theme.textTheme.bodySmall?.copyWith(color: statusColor),
              ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onEntryTap(entry),
        );
      },
    );
  }
}
