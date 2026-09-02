import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/utils/constants.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../../pet_profile/presentation/utils/ownership_accent.dart';
import '../../../pet_profile/presentation/utils/pet_accent_color.dart';
import '../screens/guardian/guardian_dashboard_helpers.dart';

/// Dashboard-specific pet presentation. It intentionally does not change the
/// shared [PetCard] used by full pet lists and organisation surfaces.
class GuardianDashboardPetCard extends StatelessWidget {
  const GuardianDashboardPetCard({
    super.key,
    required this.pet,
    required this.careState,
    required this.onTap,
    this.selected = false,
    this.showSelection = false,
  });

  final Pet pet;
  final GuardianTodayPetCareState careState;
  final VoidCallback onTap;
  final bool selected;
  final bool showSelection;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final ownership = resolvePetOwnershipAccent(context, pet, l);
    final relationship = _relationship(l);
    final careLabel = _careLabel(l);

    return Semantics(
      key: Key('guardian_dashboard_pet_card_${pet.id}'),
      button: true,
      selected: showSelection && selected,
      onTap: onTap,
      label: '${pet.name}, $relationship, $careLabel',
      excludeSemantics: true,
      child: Card(
        key: Key('guardian_dashboard_pet_card_visual_${pet.id}'),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        shape: showSelection && selected
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.primary, width: 2),
              )
            : null,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Container(
                  key: Key('guardian_dashboard_pet_photo_${pet.id}'),
                  width: 56,
                  height: 56,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: ownership.accentColor.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ownership.accentColor,
                      width: 1.5,
                    ),
                  ),
                  child: ClipOval(child: _photo(context)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            careState == GuardianTodayPetCareState.overdue
                                ? Icons.priority_high_rounded
                                : careState ==
                                      GuardianTodayPetCareState.dueToday
                                ? Icons.schedule_outlined
                                : Icons.check_circle_outline,
                            size: 14,
                            color: _careColor(),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              careLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _careColor(),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (relationship != l.myPets &&
                          MediaQuery.textScalerOf(context).scale(12) <= 18) ...[
                        const SizedBox(height: 2),
                        Text(
                          relationship,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                  ],
                ),
              ),
              if (showSelection)
                Positioned(
                  top: 6,
                  right: 6,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surface.withValues(alpha: 0.92),
                    foregroundColor: selected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                    child: Icon(
                      selected ? Icons.check : Icons.circle_outlined,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _relationship(AppLocalizations l) {
    if (pet.isShared) return l.sharedPets;
    if (pet.isFoster) return l.myFosteredPets;
    return l.myPets;
  }

  String _careLabel(AppLocalizations l) {
    return switch (careState) {
      GuardianTodayPetCareState.overdue => l.overdue,
      GuardianTodayPetCareState.dueToday => l.urgencyDueToday,
      GuardianTodayPetCareState.upcoming => l.careStatusUpcoming,
      GuardianTodayPetCareState.clear => l.careStatusAllClear,
    };
  }

  Color _careColor() {
    return switch (careState) {
      GuardianTodayPetCareState.overdue => AppColorTokens.danger,
      GuardianTodayPetCareState.dueToday => AppColorTokens.guardianPrimary,
      GuardianTodayPetCareState.upcoming => AppColorTokens.organizationActive,
      GuardianTodayPetCareState.clear => AppColorTokens.success,
    };
  }

  Widget _photo(BuildContext context) {
    final color = resolvePetAccentColor(context, pet);
    Widget image;
    if (pet.photoPath?.startsWith('asset://') ?? false) {
      image = Image.asset(
        pet.photoPath!.substring('asset://'.length),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(color),
      );
    } else if (pet.photoPath?.isNotEmpty ?? false) {
      try {
        image = Image.memory(base64Decode(pet.photoPath!), fit: BoxFit.cover);
      } catch (_) {
        // Fall through to the species placeholder for malformed stored photos.
        image = _placeholder(color);
      }
    } else {
      image = _placeholder(color);
    }

    if (!pet.passedAway) return image;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.mode(
            AppColorTokens.passedAwayPhotoOverlay,
            BlendMode.lighten,
          ),
          child: image,
        ),
        Center(
          child: Opacity(
            opacity: 0.35,
            child: Image.asset(
              'assets/rainbow_wings.png',
              width: 36,
              height: 36,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder(Color color) {
    return ColoredBox(
      color: color.withValues(alpha: 0.12),
      child: Center(
        child: AppConstants.speciesIconWidget(
          pet.species,
          size: 36,
          color: color,
        ),
      ),
    );
  }
}
