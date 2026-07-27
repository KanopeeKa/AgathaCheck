import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../pet_profile/domain/entities/pet.dart';

/// Pet thumbnail + name card for the view entry screen.
class PetEventPetCard extends StatelessWidget {
  const PetEventPetCard({super.key, required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final petColor = pet.colorValue != null
        ? Color(pet.colorValue!)
        : colorScheme.primary;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _PetAvatar(pet: pet, petColor: petColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                pet.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetAvatar extends StatelessWidget {
  const _PetAvatar({required this.pet, required this.petColor});

  final Pet pet;
  final Color petColor;

  @override
  Widget build(BuildContext context) {
    if (pet.photoPath != null && pet.photoPath!.isNotEmpty) {
      try {
        var data = pet.photoPath!;
        if (data.contains(',')) {
          data = data.split(',').last;
        }
        final bytes = base64Decode(data);
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: petColor, width: 2),
          ),
          child: ClipOval(
            child: Image.memory(bytes, width: 44, height: 44, fit: BoxFit.cover),
          ),
        );
      } catch (_) {}
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: petColor.withValues(alpha: 0.2),
        border: Border.all(color: petColor, width: 2),
      ),
      child: Icon(Icons.pets, color: petColor),
    );
  }
}
