import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/presentation/widgets/pet_card.dart';

class OrganizationPetsSection extends StatelessWidget {
  final AsyncValue petsAsync;
  final bool isSuperUser;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final AppLocalizations l;
  final String orgId;
  final bool petsExpanded;
  final void Function()? onToggleExpand;
  final void Function()? onAddPet;

  const OrganizationPetsSection({
    super.key,
    required this.petsAsync,
    required this.isSuperUser,
    required this.theme,
    required this.colorScheme,
    required this.l,
    required this.orgId,
    required this.petsExpanded,
    this.onToggleExpand,
    this.onAddPet,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.orgBlueDarker,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              key: const Key('org_pets_header'),
              borderRadius: BorderRadius.circular(8),
              onTap: onToggleExpand,
              child: Row(
                children: [
                  Icon(Icons.pets, size: 20, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(l.orgPets,
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold)),
                  ),
                  AnimatedRotation(
                    turns: petsExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more,
                        color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (petsExpanded)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: petsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, _) => Column(
                    children: [
                      Text('$e', style: TextStyle(color: colorScheme.error)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: onAddPet,
                        child: Text(l.retry),
                      ),
                    ],
                  ),
                  data: (pets) {
                    if (pets.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.pets, size: 40,
                                  color: colorScheme.outline),
                              const SizedBox(height: 8),
                              Text(l.orgNoPets,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant)),
                              if (isSuperUser && onAddPet != null) ...[
                                const SizedBox(height: 12),
                                FilledButton.icon(
                                  key: const Key('org_add_pet_empty'),
                                  onPressed: onAddPet,
                                  icon: const Icon(Icons.add, size: 18),
                                  label: Text(l.orgAddPet),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        ...pets.map((pet) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: PetCard(
                            pet: pet,
                            onTap: () => context.push('/pet/${pet.id}'),
                          ),
                        )),
                        if (isSuperUser && onAddPet != null) ...[
                          const Divider(),
                          OutlinedButton.icon(
                            key: const Key('org_add_pet_button'),
                            onPressed: onAddPet,
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(l.orgAddPet),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
