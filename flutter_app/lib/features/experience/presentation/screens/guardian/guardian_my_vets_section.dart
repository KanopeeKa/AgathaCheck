import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_color_tokens.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_profile/domain/entities/pet.dart';
import '../../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../vet/domain/entities/vet.dart';
import '../../../../vet/presentation/providers/vet_providers.dart';
import '../../../../vet/presentation/widgets/care_team_card.dart';
import '../../widgets/guardian_dashboard_section_header.dart';
import '../../widgets/guardian_illustrated_empty_state.dart';

/// Care team dashboard section — warm clinic cards with linked-pet previews.
class GuardianMyVetsSection extends ConsumerWidget {
  const GuardianMyVetsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    final vetListAsync = ref.watch(vetListProvider);
    final petsAsync = ref.watch(petListProvider);
    final vets = vetListAsync.valueOrNull ?? const <Vet>[];
    final showAllAction = auth.accessToken != null && vets.isNotEmpty;

    return Semantics(
      container: true,
      label: l.myVets,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GuardianDashboardSectionHeader(
            title: l.careTeamEyebrow,
            actionLabel: showAllAction ? l.allCareTeams : null,
            onAction: showAllAction ? () => context.go('/g/vets') : null,
            actionKey: showAllAction
                ? const Key('guardian_dashboard_all_care_teams')
                : null,
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColorTokens.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: auth.accessToken == null
                  ? const SizedBox(
                      key: Key('guardian_vets_auth_waiting'),
                      height: 24,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : vetListAsync.when(
                      loading: () => const SizedBox(
                        key: Key('guardian_vets_loading'),
                        height: 24,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      error: (_, __) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline),
                          const SizedBox(height: 4),
                          Text(l.error),
                          TextButton.icon(
                            onPressed: () =>
                                ref.read(vetListProvider.notifier).refresh(),
                            icon: const Icon(Icons.refresh, size: 18),
                            label: Text(l.retry),
                          ),
                        ],
                      ),
                      data: (resolvedVets) {
                        if (resolvedVets.isEmpty) {
                          return GuardianIllustratedEmptyState(
                            key: const Key('guardian_dashboard_empty_vets'),
                            assetPath:
                                'assets/dashboard/guardian-empty-vets.png',
                            title: l.guardianEmptyVetTitle,
                            body: l.guardianEmptyVetBody,
                            actionLabel: l.addVet,
                            actionKey: const Key(
                              'guardian_dashboard_empty_vets_action',
                            ),
                            onAction: () => context.go('/g/vets/add'),
                          );
                        }
                        final pets = petsAsync.valueOrNull;
                        final linkedPetsByVetId = pets == null
                            ? null
                            : _linkedPetsByVetId(pets);
                        return Column(
                          children: [
                            for (final vet in resolvedVets)
                              CareTeamCard(
                                vet: vet,
                                linkedPets:
                                    linkedPetsByVetId?[vet.id] ?? const <Pet>[],
                                linkedPetCount: pets == null
                                    ? null
                                    : (linkedPetsByVetId?[vet.id] ??
                                              const <Pet>[])
                                          .length,
                                onTap: () => context.go('/g/vets/${vet.id}'),
                              ),
                          ],
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<Pet>> _linkedPetsByVetId(List<Pet> pets) {
    final grouped = <String, List<Pet>>{};
    for (final pet in pets) {
      final vetId = pet.vetId;
      if (vetId == null || vetId.isEmpty) continue;
      grouped.putIfAbsent(vetId, () => <Pet>[]).add(pet);
    }
    return grouped;
  }
}
