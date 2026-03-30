import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/pet.dart';
import '../../controllers/chip_reminder_controller.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/utils/constants.dart';

class ChipReminderCard extends ConsumerWidget {
  const ChipReminderCard({required this.pet, super.key});

  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        color: colorScheme.secondaryContainer.withAlpha(80),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.memory, color: colorScheme.secondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppConstants.identificationTitle(pet.species, pet.name),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                AppConstants.identificationMessage(pet.species),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSecondaryContainer.withAlpha(200),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    key: const Key('chip_dismiss_button'),
                    onPressed: () async {
                      final controller = ChipReminderController(ref);
                      await controller.dismissChipReminder(pet);
                    },
                    child: Text('Dismiss'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    key: const Key('chip_snooze_button'),
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
