import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/pet.dart';
import '../providers/pet_providers.dart';
import '../../../../l10n/app_localizations.dart';

class NeuterReminderCard extends ConsumerWidget {
  const NeuterReminderCard({required this.pet, super.key});

  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        color: colorScheme.tertiaryContainer.withAlpha(80),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: colorScheme.tertiary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      pet.species == 'Other'
                          ? 'Has ${pet.name} been neutered or spayed?'
                          : 'Consider neutering ${pet.name}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                pet.species == 'Other'
                    ? 'Neutering or spaying is not suitable for every species. '
                      'If your pet is a species where neutering applies, it can '
                      'help prevent certain health issues and control the population. '
                      'Talk to your vet to find out if it is appropriate for your pet.'
                    : 'Neutering or spaying helps prevent certain cancers, '
                      'reduces unwanted behaviours, and helps control the pet '
                      'population. It can also lower the risk of infections and '
                      'increase your pet\'s lifespan. Talk to your vet about the '
                      'best time for the procedure.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onTertiaryContainer.withAlpha(200),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    key: const Key('neuter_dismiss_button'),
                    onPressed: () async {
                      final controller = NeuterReminderController(ref);
                      await controller.dismissNeuterReminder(pet);
                    },
                    child: Text(AppLocalizations.of(context)!.dontWantToNeuter),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    key: const Key('neuter_snooze_button'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context)!.reminderSnooze),
                        ),
                      );
                    },
                    child: Text(AppLocalizations.of(context)!.snooze),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
