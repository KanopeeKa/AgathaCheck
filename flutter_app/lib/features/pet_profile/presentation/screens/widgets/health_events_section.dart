import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/pet.dart';
import '../../../health_tracking/domain/entities/health_entry.dart';
import '../../controllers/health_events_controller.dart';
import '../../../../l10n/app_localizations.dart';

class HealthEventsSection extends ConsumerStatefulWidget {
  const HealthEventsSection({required this.petId, this.pet, super.key});

  final String petId;
  final Pet? pet;

  @override
  ConsumerState<HealthEventsSection> createState() => _HealthEventsSectionState();
}

class _HealthEventsSectionState extends ConsumerState<HealthEventsSection> {
  HealthEntryType? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final controller = HealthEventsController(ref);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // You may want to move filter state to the controller for more robust logic
    final l = AppLocalizations.of(context)!;

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
                      onPressed: () {
                        // Delegate navigation/filter logic to controller
                        controller.onAddEntry(context, widget.petId, _selectedFilter);
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l.addEntry),
                    ),
                  ),
                ],
              ),
            ),
            // ...rest of the health events UI...
          ],
        ),
      ),
    );
  }
}
