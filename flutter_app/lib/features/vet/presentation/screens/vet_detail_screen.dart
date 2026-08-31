import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../providers/vet_providers.dart';
import '../utils/vet_accent.dart';
import '../widgets/care_team_identity_card.dart';
import '../widgets/care_team_pet_row.dart';

/// Display-first care team detail screen. Edit is a secondary card action.
class VetDetailScreen extends ConsumerWidget {
  const VetDetailScreen({
    super.key,
    required this.vetId,
    this.listPath = '/g/vets',
  });

  final String vetId;
  final String listPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final vetListAsync = ref.watch(vetListProvider);
    final pets = ref.watch(petListProvider).valueOrNull ?? [];

    return vetListAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l.failedToLoadVets('$e'))),
      data: (vets) {
        final vet = vets.where((v) => v.id == vetId).firstOrNull;
        if (vet == null) {
          return Center(child: Text(l.vetNotFound));
        }

        final linkedPets = pets.where((p) => p.vetId == vet.id).toList();
        final accent = resolveVetAccent(
          context,
          organizationId: vet.organizationId,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CareTeamIdentityCard(
                vet: vet,
                accent: accent,
                onEdit: () => context.go('$listPath/edit/$vetId'),
              ),
              const SizedBox(height: 24),
              Text(
                l.careTeamPetsCaredFor,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (linkedPets.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.careTeamNoLinkedPets,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        key: const Key('care_team_link_pets_button'),
                        onPressed: () => context.go('$listPath/edit/$vetId'),
                        child: Text(l.editCareTeam),
                      ),
                    ],
                  ),
                )
              else
                ...linkedPets.asMap().entries.map(
                  (entry) => CareTeamPetRow(
                    key: Key('care_team_pet_row_${entry.value.id}'),
                    pet: entry.value,
                    showDivider: entry.key < linkedPets.length - 1,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
