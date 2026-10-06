import 'package:flutter/material.dart';
import 'package:pet_profile_app/core/theme/experience_colors.dart';
import 'package:pet_profile_app/core/utils/calendar_date.dart';
import 'package:pet_profile_app/core/utils/constants.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import 'pet_detail_profile_detail_rows.dart';
import 'pet_detail_profile_info_chips.dart';

/// Presentational layout for the pet detail profile header card.
class PetDetailProfileCardLayout extends StatelessWidget {
  const PetDetailProfileCardLayout({
    super.key,
    required this.pet,
    required this.theme,
    required this.l,
    required this.canEdit,
    required this.viewerRole,
    required this.weightChipLabel,
    required this.onEdit,
  });

  final Pet pet;
  final ThemeData theme;
  final AppLocalizations l;
  final bool canEdit;
  final PetViewerRole viewerRole;
  final String? weightChipLabel;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final photoWidth = (constraints.maxWidth * 0.38).clamp(96.0, 120.0);
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: photoWidth,
                    child: PetPhoto(pet: pet),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Semantics(
                                  header: true,
                                  child: Text(
                                    pet.name,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              if (canEdit)
                                IconButton(
                                  key: const Key('edit_pet_button'),
                                  icon: Icon(
                                    Icons.edit,
                                    size: 20,
                                    color: colorScheme.primary,
                                  ),
                                  tooltip: l.editPet,
                                  onPressed: onEdit,
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              key: const Key('pet_responsibility_label'),
                              petResponsibilityLabel(l, pet, viewerRole),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          PetDetailProfileInfoChips(
                            pet: pet,
                            weightChipLabel: weightChipLabel,
                          ),
                          if (pet.bio.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              pet.bio,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          PetDetailProfileDetailRows(pet: pet, theme: theme),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
