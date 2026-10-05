import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../../pet_profile/presentation/utils/pet_accent_color.dart';
import '../../../../l10n/app_localizations.dart';

class NotificationSettingsMutedPetsSection extends ConsumerWidget {
  const NotificationSettingsMutedPetsSection({
    super.key,
    required this.mutedPetIds,
    required this.onMutedChanged,
  });

  final List<String> mutedPetIds;
  final void Function(List<String> ids) onMutedChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final petsAsync = ref.watch(petListProvider);
    final pets = petsAsync.valueOrNull ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            l.mutedPets,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            l.notificationSettingsMutedPetsHelp,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (pets.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              l.notificationSettingsNoPets,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          ...pets.map((pet) {
            final isMuted = mutedPetIds.contains(pet.id);
            final petColor = resolvePetAccentColor(context, pet);
            return SwitchListTile(
              title: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: petColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(pet.name)),
                ],
              ),
              subtitle: Text(
                isMuted
                    ? l.notificationSettingsPetMuted
                    : l.notificationSettingsPetActive,
              ),
              value: isMuted,
              onChanged: (v) {
                final next = List<String>.from(mutedPetIds);
                if (v) {
                  next.add(pet.id);
                } else {
                  next.remove(pet.id);
                }
                onMutedChanged(next);
              },
              secondary: Icon(
                isMuted ? Icons.notifications_off : Icons.notifications_active,
                color: isMuted ? theme.colorScheme.onSurfaceVariant : petColor,
              ),
            );
          }),
      ],
    );
  }
}
