import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_profile/domain/entities/pet.dart';
import '../../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../vet/domain/entities/vet.dart';
import '../../../../vet/presentation/providers/vet_providers.dart';
import '../../../../vet/presentation/widgets/care_team_card.dart';
import '../../widgets/pet_care_dashboard_ambient_deco.dart';
import '../../widgets/pet_care_operations_desk_layout.dart';
import '../../widgets/pet_care_dashboard_section_header.dart';
import '../../widgets/pet_care_illustrated_empty_state.dart';

/// Care team dashboard section — warm clinic cards with linked-pet previews.
class PetCareMyVetsSection extends ConsumerWidget {
  const PetCareMyVetsSection({super.key, this.useWideDeskLayout = false});

  /// Whether the guardian desk is in the wide two-column layout (content
  /// width ≥ [PetCareOperationsDeskLayout.wideBreakpoint]).
  final bool useWideDeskLayout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    final vetListAsync = ref.watch(vetListProvider);
    final petsAsync = ref.watch(petListProvider);
    final vets = vetListAsync.valueOrNull ?? const <Vet>[];
    final showAllAction = auth.accessToken != null && vets.isNotEmpty;

    final showPuppyDeco = petCareCareTeamPuppyDecoAllowed(
      useWideDeskLayout: useWideDeskLayout,
      hasCareTeamCards: auth.accessToken != null && vets.isNotEmpty,
    );

    final sectionBody = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PetCareDashboardSectionHeader(title: l.careTeamEyebrow),
        const SizedBox(height: 10),
        auth.accessToken == null
            ? const SizedBox(
                key: Key('guardian_vets_auth_waiting'),
                height: 24,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
                    return PetCareIllustratedEmptyState(
                      key: const Key('guardian_dashboard_empty_vets'),
                      assetPath: 'assets/dashboard/guardian-empty-vets.png',
                      title: l.petCareEmptyVetTitle,
                      body: l.petCareEmptyVetBody,
                      actionLabel: l.addVet,
                      actionKey: const Key(
                        'guardian_dashboard_empty_vets_action',
                      ),
                      onAction: () => context.go('/pc/vets/add'),
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
                              : (linkedPetsByVetId?[vet.id] ?? const <Pet>[])
                                    .length,
                          onTap: () {
                            final returnTo = Uri.encodeComponent('/pc/home');
                            context.go('/pc/vets/${vet.id}?returnTo=$returnTo');
                          },
                        ),
                    ],
                  );
                },
              ),
        if (showAllAction)
          PetCareDashboardSectionLink(
            linkKey: const Key('guardian_dashboard_all_care_teams'),
            label: l.allCareTeams,
            onPressed: () => context.go('/pc/vets'),
          ),
      ],
    );

    return Semantics(
      container: true,
      label: l.myVets,
      child: showPuppyDeco
          ? Stack(
              // Fill IntrinsicHeight stretch so the puppy anchors to the
              // column bottom, not just the content height.
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                sectionBody,
                Positioned(
                  right: 0,
                  bottom: showAllAction ? 40 : 0,
                  child: const PetCareCareTeamPuppyDeco(),
                ),
              ],
            )
          : sectionBody,
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
