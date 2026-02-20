import 'dart:convert';

import 'package:flutter/material.dart';

import '../../domain/entities/pet.dart';

/// A Material 3 card widget that displays a pet's summary information.
///
/// Shows the pet's photo (or a placeholder icon), name, breed,
/// and species. Tapping the card triggers [onTap].
class PetCard extends StatelessWidget {
  /// Creates a [PetCard] for the given [pet].
  const PetCard({
    super.key,
    required this.pet,
    this.onTap,
    this.onDelete,
  });

  /// The pet to display.
  final Pet pet;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  /// Called when the delete button is pressed.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildAvatar(colorScheme),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pet.breed.isNotEmpty
                          ? '${pet.species} - ${pet.breed}'
                          : pet.species,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (pet.age != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${pet.age!.toStringAsFixed(1)} years old',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: Icon(Icons.delete_outline, color: colorScheme.error),
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ColorScheme colorScheme) {
    if (pet.photoPath != null && pet.photoPath!.isNotEmpty) {
      try {
        final bytes = base64Decode(pet.photoPath!);
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            bytes,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {
        // Fall through to placeholder
      }
    }

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _speciesIcon(pet.species),
        size: 32,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }

  IconData _speciesIcon(String species) {
    switch (species.toLowerCase()) {
      case 'dog':
        return Icons.pets;
      case 'cat':
        return Icons.pets;
      case 'bird':
        return Icons.flutter_dash;
      case 'fish':
        return Icons.water;
      case 'rabbit':
        return Icons.cruelty_free;
      default:
        return Icons.pets;
    }
  }
}
