import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../domain/entities/health_entry.dart';

class HealthEntryPetStrip extends StatelessWidget {
  const HealthEntryPetStrip({super.key, this.pet, required this.colorScheme});

  final Pet? pet;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final petColor = pet?.colorValue != null
        ? Color(pet!.colorValue!)
        : colorScheme.surfaceContainerHighest;

    return Container(
      width: 52,
      decoration: BoxDecoration(color: petColor.withValues(alpha: 0.18)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildAvatar(petColor),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              pet?.name ?? '?',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(Color petColor) {
    if (pet?.photoPath != null && pet!.photoPath!.isNotEmpty) {
      try {
        final bytes = base64Decode(pet!.photoPath!);
        return Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: petColor, width: 2),
          ),
          child: ClipOval(
            child: Image.memory(
              bytes,
              width: 26,
              height: 26,
              fit: BoxFit.cover,
            ),
          ),
        );
      } catch (_) {}
    }
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: petColor.withValues(alpha: 0.25),
        border: Border.all(color: petColor, width: 2),
      ),
      child: Icon(Icons.pets, size: 14, color: petColor),
    );
  }
}

class HealthEntryFrequencyBadge extends StatelessWidget {
  const HealthEntryFrequencyBadge({
    super.key,
    required this.frequency,
    this.interval = 1,
  });

  final HealthFrequency frequency;
  final int interval;

  String _displayLabel(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (frequency == HealthFrequency.once) return l.doesNotRepeat;
    if (frequency == HealthFrequency.custom) return l.custom;
    final period = frequency.label;
    if (interval == 1) return l.everyPeriod(period);
    return l.everyNPeriods(interval, '${period}s');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _displayLabel(context),
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 10,
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
