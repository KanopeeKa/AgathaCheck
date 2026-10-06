import 'package:flutter/material.dart';
import 'package:pet_profile_app/core/theme/experience_colors.dart';
import 'package:pet_profile_app/core/utils/calendar_date.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

/// Neutered, microchip, and insurance rows on the pet detail profile card.
class PetDetailProfileDetailRows extends StatelessWidget {
  const PetDetailProfileDetailRows({
    super.key,
    required this.pet,
    required this.theme,
  });

  final Pet pet;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pet.neuteredDate != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.check_circle,
                size: 18,
                color: context.experienceColors.success,
              ),
              const SizedBox(width: 8),
              Text(
                l.neuteredSpayed(formatCalendarDateMedium(pet.neuteredDate!)),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
        if (pet.chipId.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.memory, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                l.idLabel(pet.chipId),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
        if (pet.insurance.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.insuranceDetails,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pet.insurance,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
