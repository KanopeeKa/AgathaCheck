import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../domain/entities/health_entry.dart';

/// Lightweight circular pet photo for [CareEventRow] leading slot.
class CareEventRowPetAvatar extends StatelessWidget {
  const CareEventRowPetAvatar({
    super.key,
    this.pet,
    this.petName,
    required this.colorScheme,
  });

  final Pet? pet;
  final String? petName;
  final ColorScheme colorScheme;

  static const size = 32.0;

  Color get _petColor {
    if (pet?.colorValue != null) return Color(pet!.colorValue!);
    return colorScheme.surfaceContainerHighest;
  }

  @override
  Widget build(BuildContext context) {
    final petColor = _petColor;

    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: _buildAvatar(petColor),
      ),
    );
  }

  Widget _buildAvatar(Color petColor) {
    if (pet?.photoPath != null && pet!.photoPath!.isNotEmpty) {
      try {
        var data = pet!.photoPath!;
        if (data.contains(',')) {
          data = data.split(',').last;
        }
        final bytes = base64Decode(data);
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: petColor, width: 1.5),
          ),
          child: ClipOval(
            child: Image.memory(bytes, width: size, height: size, fit: BoxFit.cover),
          ),
        );
      } catch (_) {}
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: petColor.withValues(alpha: 0.22),
        border: Border.all(color: petColor, width: 1.5),
      ),
      child: Icon(Icons.pets, size: 16, color: petColor),
    );
  }
}

String careEventRowDisplayPetName(Pet? pet, HealthEntry entry, AppLocalizations l) {
  final fromPet = pet?.name;
  if (fromPet != null && fromPet.isNotEmpty) return fromPet;
  final fromEntry = entry.petName;
  if (fromEntry != null && fromEntry.isNotEmpty) return fromEntry;
  return l.unknownPet;
}
