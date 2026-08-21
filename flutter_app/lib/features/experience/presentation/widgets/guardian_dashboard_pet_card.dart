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
  });

  final Pet pet;
  final GuardianTodayPetCareState careState;
  final VoidCallback onTap;

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
      onTap: onTap,
      label: '${pet.name}, $relationship, $careLabel',
      excludeSemantics: true,
      child: Card(
        key: Key('guardian_dashboard_pet_card_visual_${pet.id}'),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                key: Key('guardian_dashboard_pet_photo_${pet.id}'),
                height: 104,
                child: _photo(context),
              ),
              Container(height: 3, color: ownership.accentColor),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
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
                    Text(
                      careLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (relationship != l.myPets) ...[
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
