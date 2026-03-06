import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/presentation/widgets/pet_card.dart';
import '../providers/organization_providers.dart';

class OrganizationPetsScreen extends ConsumerWidget {
  const OrganizationPetsScreen({super.key, required this.orgId});

  final int orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(orgPetsProvider(orgId));
    final isSuperUser = ref.watch(isOrgSuperUserProvider(orgId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: AppLogoTitle(title: l.orgPets),
        leading: IconButton(
          key: const Key('org_pets_back'),
          icon: const Icon(Icons.arrow_back),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => context.pop(),
        ),
      ),
      body: petsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text('$e'),
              const SizedBox(height: 8),
              ElevatedButton(
                key: const Key('org_pets_retry'),
                onPressed: () => ref.invalidate(orgPetsProvider(orgId)),
                child: Text(l.retry),
              ),
            ],
          ),
        ),
        data: (pets) {
          if (pets.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      Icons.pets,
                      size: 80,
                      color: colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.orgNoPets,
                    style: theme.textTheme.headlineSmall,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pets.length,
            itemBuilder: (context, index) {
              final pet = pets[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    PetCard(
                      pet: pet,
                      onTap: () => context.push('/pet/${pet.id}'),
                    ),
                    if (isSuperUser)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            key: Key('org_transfer_pet_${pet.id}'),
                            onPressed: () => context.push(
                                '/organizations/$orgId/transfer/${pet.id}'),
                            icon: const Icon(Icons.swap_horiz, size: 18),
                            label: Text(l.transferPet),
                            style: TextButton.styleFrom(
                              foregroundColor: colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: isSuperUser
          ? FloatingActionButton.extended(
              key: const Key('org_add_pet_fab'),
              onPressed: () => context.push('/add?orgId=$orgId'),
              tooltip: l.orgAddPet,
              icon: const Icon(Icons.add),
              label: Text(l.orgAddPet),
            )
          : null,
    );
  }
}
