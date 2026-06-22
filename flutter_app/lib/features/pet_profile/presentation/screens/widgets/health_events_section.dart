import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/pet.dart';
import '../../../../health_tracking/domain/entities/health_entry.dart';
import '../../../../health_tracking/presentation/providers/health_providers.dart';
import '../../controllers/health_events_controller.dart';
import '../../../../../l10n/app_localizations.dart';

class HealthEventsSection extends ConsumerStatefulWidget {
  const HealthEventsSection({required this.petId, this.pet, super.key});

  final String petId;
  final Pet? pet;

  @override
  ConsumerState<HealthEventsSection> createState() => _HealthEventsSectionState();
}

class _HealthEventsSectionState extends ConsumerState<HealthEventsSection> {
  HealthEntryType? _selectedFilter;

  IconData _iconForType(HealthEntryType type) {
    switch (type) {
      case HealthEntryType.medication:
        return Icons.medication_outlined;
      case HealthEntryType.preventive:
        return Icons.shield_outlined;
      case HealthEntryType.vetVisit:
        return Icons.local_hospital_outlined;
      case HealthEntryType.procedure:
        return Icons.medical_services_outlined;
      case HealthEntryType.familyEvent:
        return Icons.event_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = HealthEventsController(ref);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;
    final dateFormat = DateFormat.yMMMd();
    final entriesAsync = ref.watch(petHealthEntriesByIdProvider(widget.petId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          leading: Icon(Icons.list_alt, color: colorScheme.primary),
          title: Text(l.healthEvents,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Tooltip(
                    message: l.addEntry,
                    child: FilledButton.tonalIcon(
                      key: const Key('add_health_event_button'),
                      onPressed: () {
                        controller.onAddEntry(context, widget.petId, _selectedFilter);
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l.addEntry),
                    ),
                  ),
                ],
              ),
            ),
            entriesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(e.toString(),
                    style: TextStyle(color: colorScheme.error)),
              ),
              data: (entries) {
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
                        ? entry.type.label
                        : '${entry.type.label} · ${entry.dosage}';

                    final Widget statusLine;
                    if (entry.isCompleted) {
                      statusLine = Text(
                        l.completed,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: colorScheme.primary),
                      );
                    } else if (entry.isOverdue) {
                      statusLine = Text(
                        '${l.overdue} · ${dateFormat.format(entry.nextDueDate)}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: colorScheme.error),
                      );
                    } else {
                      statusLine = Text(
                        dateFormat.format(entry.nextDueDate),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                      );
                    }

                    return ListTile(
                      leading: Icon(
                        _iconForType(entry.type),
                        color: entry.isOverdue
                            ? colorScheme.error
                            : colorScheme.primary,
                      ),
                      title: Text(entry.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(detail),
                          statusLine,
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go(
                          '/pet/${widget.petId}/health/edit/${entry.id}'),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
