import 'package:flutter/material.dart';

import '../../../../core/theme/experience_colors.dart';
import '../../domain/entities/pet.dart';

/// Photo ring / accent: org-guardianship pets use system org teal on guardian surfaces.
Color resolvePetAccentColor(BuildContext context, Pet pet) {
  final xp = context.experienceColors;
  if (pet.organizationId != null && pet.organizationId!.isNotEmpty) {
    return xp.organizationPrimary;
  }
  if (pet.colorValue != null) {
    return Color(pet.colorValue!);
  }
  return Theme.of(context).colorScheme.primary;
}
