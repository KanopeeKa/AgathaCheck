import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Pet row data for mute toggles (built by the settings screen).
class NotificationSettingsPetMuteRow {
  const NotificationSettingsPetMuteRow({
    required this.id,
    required this.name,
    required this.accentColor,
  });

  final String id;
  final String name;
  final Color accentColor;
}

class NotificationSettingsMutedPetsSection extends StatelessWidget {
  const NotificationSettingsMutedPetsSection({
    super.key,
    required this.pets,
    required this.mutedPetIds,
    required this.onMutedChanged,
  });

  final List<NotificationSettingsPetMuteRow> pets;
  final List<String> mutedPetIds;
  final void Function(List<String> ids) onMutedChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

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
            return SwitchListTile(
              title: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: pet.accentColor,
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
                color: isMuted
                    ? theme.colorScheme.onSurfaceVariant
                    : pet.accentColor,
              ),
            );
          }),
      ],
    );
  }
}
