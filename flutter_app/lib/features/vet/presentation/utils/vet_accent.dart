import 'package:flutter/material.dart';

import '../../../../core/theme/experience_colors.dart';

/// Plum vs green cues for vet cards (navigation v2).
class VetAccent {
  const VetAccent({
    required this.isOrganization,
    required this.primary,
    required this.onPrimary,
    required this.surface,
  });

  final bool isOrganization;
  final Color primary;
  final Color onPrimary;
  final Color surface;
}

VetAccent resolveVetAccent(BuildContext context, {String? organizationId}) {
  final xp = context.experienceColors;
  if (organizationId != null && organizationId.isNotEmpty) {
    return VetAccent(
      isOrganization: true,
      primary: xp.organizationPrimary,
      onPrimary: xp.organizationOnPrimary,
      surface: xp.organizationLight.withAlpha(120),
    );
  }
  return VetAccent(
    isOrganization: false,
    primary: xp.petCarePrimary,
    onPrimary: xp.guardianOnPrimary,
    surface: xp.guardianLight.withAlpha(120),
  );
}

String vetTownLabel(String address) {
  final trimmed = address.trim();
  if (trimmed.isEmpty) return '';
  final parts = trimmed
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '';
  if (parts.length == 1) return parts.first;
  return parts.last;
}
