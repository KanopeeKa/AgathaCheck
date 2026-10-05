import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/utils/calendar_date.dart';
import '../../../../../core/theme/experience_colors.dart';
import '../../../../../core/utils/constants.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../people/people.dart';
import 'pet_detail_primary_vet_field.dart';
import '../../../../weight_tracking/presentation/providers/weight_providers.dart';
import '../../../domain/entities/pet.dart';
import '../../../domain/services/pet_detail_actions.dart';
import '../../utils/pet_responsibility_label.dart';
import 'pet_info_chip.dart';
import 'pet_photo.dart';

/// The header card on the pet detail screen: photo, name, quick-info chips,
/// assigned vet selector, and optional bio / neuter / chip / insurance rows.
///
/// The photo column width is computed from a [LayoutBuilder] so the card
/// stays usable at 320 logical px without horizontal overflow.
class PetDetailProfileCard extends ConsumerWidget {
  const PetDetailProfileCard({
    super.key,
    required this.pet,
    required this.viewerContext,
  });

  final Pet pet;
  final PetDetailContext viewerContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final petPeopleAsync = ref.watch(petPeopleProvider(pet.id));
    final primaryVetId = primaryVetRelationship(
      petPeopleAsync.valueOrNull,
    )?.contactId;

    final displayWeight = pet.weight;
    final l = AppLocalizations.of(context)!;
    final canEdit = viewerContext.can(PetDetailAction.editProfile);
    final canAssignVet = viewerContext.can(PetDetailAction.assignVet);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Photo column: 38 % of card width, bounded to [96, 120] px.
            // At 320 logical px the card is ~288 px wide, giving ~109 px for
            // the photo and ≥147 px for the info area — reliable at 320 px.
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
                                // Semantics header so screen readers announce
                                // the pet name as a heading landmark.
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
                                  onPressed: () =>
                                      context.go('/edit/${pet.id}'),
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
                              petResponsibilityLabel(
                                l,
                                pet,
                                viewerContext.role,
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Semantics(
                                identifier: 'pet_detail_species_chip',
                                label: pet.species,
                                child: PetInfoChipWidget(
                                  iconWidget: AppConstants.speciesIconWidget(
                                    pet.species,
                                    size: 18,
                                  ),
                                  label: pet.species,
                                ),
                              ),
                              if (pet.breed.isNotEmpty)
                                PetInfoChip(icon: Icons.pets, label: pet.breed),
                              if (pet.gender != null && pet.gender!.isNotEmpty)
                                PetInfoChip(
                                  icon: pet.gender == 'Male'
                                      ? Icons.male
                                      : Icons.female,
                                  label: pet.gender!,
                                ),
                              if (pet.ageDisplay != null)
                                PetInfoChip(
                                  icon: Icons.cake,
                                  label: pet.ageDisplay!,
                                ),
                              if (displayWeight != null)
                                Consumer(
                                  builder: (context, ref, _) {
                                    final unit = ref.watch(
                                      weightUnitProvider(pet.id),
                                    );
                                    final converted = convertWeight(
                                      displayWeight,
                                      unit,
                                    );
                                    return PetInfoChip(
                                      icon: Icons.monitor_weight,
                                      label:
                                          '${converted.toStringAsFixed(1)} ${weightUnitLabel(unit)}',
                                    );
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (canAssignVet)
                            PetDetailPrimaryVetField(
                              petId: pet.id,
                              currentContactId: primaryVetId,
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
                          if (pet.neuteredDate != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 18,
                                  color: context.experienceColors.success,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l.neuteredSpayed(
                                    formatCalendarDateMedium(pet.neuteredDate!),
                                  ),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (pet.chipId.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.memory,
                                  size: 18,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.idLabel(pet.chipId),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (pet.insurance.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.shield,
                                  size: 18,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.insuranceDetails,
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        pet.insurance,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
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
