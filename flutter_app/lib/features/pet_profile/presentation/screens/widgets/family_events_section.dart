import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/pet.dart';
import '../../../../../l10n/app_localizations.dart';

class FamilyEventsSection extends ConsumerWidget {
  const FamilyEventsSection({required this.petId, required this.pet, super.key});

  final String petId;
  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: ExpansionTile(
          key: const Key('family_events_section'),
          leading: Icon(Icons.family_restroom, size: 20, color: colorScheme.primary),
          title: Text(l.familyEvents,
              style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold)),
          children: const [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  // ...rest of the family events UI, now call controller for logic...
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
