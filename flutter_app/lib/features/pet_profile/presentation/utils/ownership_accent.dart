import 'package:flutter/material.dart';

import '../../../../core/theme/experience_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../organization/presentation/utils/foster_placement_display.dart';
import '../../domain/entities/pet.dart';

/// Ownership accent kind for pets (navigation v2 plum vs green).
enum PetOwnershipKind { guardianOwned, organizationLinked }

/// Resolved plum/green accent for a pet surface.
class PetOwnershipAccent {
  const PetOwnershipAccent({
    required this.kind,
    required this.accentColor,
    required this.onAccentColor,
    this.fosterLabel,
  });

  final PetOwnershipKind kind;
  final Color accentColor;
  final Color onAccentColor;

  /// Non-null when the pet is in active foster care (always org green styling).
  final String? fosterLabel;

  bool get isOrganizationLinked => kind == PetOwnershipKind.organizationLinked;
  bool get showsFosterLabel => fosterLabel != null && fosterLabel!.isNotEmpty;
}

bool _isOrganizationLinked(Pet pet) =>
    pet.organizationId != null && pet.organizationId!.isNotEmpty;

/// Photo ring / avatar accent: plum for guardian-owned, green for org-linked.
Color resolvePetOwnershipAccentColor(BuildContext context, Pet pet) {
  final xp = context.experienceColors;
  if (_isOrganizationLinked(pet)) {
    return xp.organizationPrimary;
  }
  if (pet.colorValue != null) {
    return Color(pet.colorValue!);
  }
  return xp.guardianPrimary;
}

/// Central ownership accent resolver (navigation v2).
PetOwnershipAccent resolvePetOwnershipAccent(
  BuildContext context,
  Pet pet,
  AppLocalizations l,
) {
  final xp = context.experienceColors;
  final isOrgLinked = _isOrganizationLinked(pet);
  final accentColor = resolvePetOwnershipAccentColor(context, pet);
  final onAccentColor = isOrgLinked
      ? xp.organizationOnPrimary
      : xp.guardianOnPrimary;

  final fosterLine = petFosterPlacementCardLine(l, pet);
  final fosterLabel =
      fosterLine ?? (pet.isFoster ? l.fosterPlacementInProgress : null);

  return PetOwnershipAccent(
    kind: isOrgLinked
        ? PetOwnershipKind.organizationLinked
        : PetOwnershipKind.guardianOwned,
    accentColor: accentColor,
    onAccentColor: onAccentColor,
    fosterLabel: fosterLabel,
  );
}

/// Foster label row uses org green regardless of guardian/org pet ownership.
Color fosterOwnershipAccentColor(BuildContext context) =>
    context.experienceColors.organizationPrimary;
