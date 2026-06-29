import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../domain/entities/pet.dart';
import '../../controllers/other_events_controller.dart';
import 'pet_event_entry_list.dart';

class OtherEventsSection extends ConsumerWidget {
  const OtherEventsSection({required this.petId, this.pet, super.key});

  final String petId;
  final Pet? pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = OtherEventsController(ref);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;
    final entriesAsync = ref.watch(petOtherEventsByIdProvider(petId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          key: const Key('other_events_section'),
          leading: Icon(Icons.event_note_outlined, color: colorScheme.primary),
          title: Text(
            l.otherEvents,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Tooltip(
                    message: l.addOtherEvent,
                    child: FilledButton.tonalIcon(
                      key: const Key('add_other_event_button'),
                      onPressed: () => controller.onAddEntry(context, petId),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l.addOtherEvent),
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
                child: Text(
                  e.toString(),
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
              data: (entries) => PetEventEntryList(
                entries: entries,
                petId: petId,
                onEntryTap: (entry) =>
                    context.go('/pet/$petId/other/edit/${entry.id}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
