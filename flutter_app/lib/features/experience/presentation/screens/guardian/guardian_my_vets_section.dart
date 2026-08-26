import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_color_tokens.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_profile/domain/entities/pet.dart';
import '../../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../vet/presentation/providers/vet_providers.dart';
import '../../../../vet/presentation/widgets/vet_compact_row.dart';
import '../../widgets/guardian_illustrated_empty_state.dart';

/// My Vets dashboard section — compact scannable rows, uncapped.
class GuardianMyVetsSection extends ConsumerWidget {
  const GuardianMyVetsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    final vetListAsync = ref.watch(vetListProvider);
    final petsAsync = ref.watch(petListProvider);

    return Semantics(
      container: true,
      label: l.myVets,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColorTokens.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (auth.accessToken == null)
                const SizedBox(
                  key: Key('guardian_vets_auth_waiting'),
                  height: 24,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                vetListAsync.when(
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
                  data: (vets) {
                    if (vets.isEmpty) {
                      return GuardianIllustratedEmptyState(
                        key: const Key('guardian_dashboard_empty_vets'),
                        assetPath: 'assets/dashboard/guardian-empty-vets.png',
                        title: l.guardianEmptyVetTitle,
                        body: l.guardianEmptyVetBody,
                        actionLabel: l.addVet,
                        actionKey: const Key(
                          'guardian_dashboard_empty_vets_action',
                        ),
                        onAction: () => context.go('/g/vets/add'),
                      );
                    }
                    return Column(
                      children: [
                        ...vets.map(
                          (vet) => VetCompactRow(
                            vet: vet,
                            linkedPetCount: petsAsync.hasValue
                                ? _linkedPetCount(vet.id, petsAsync.value!)
                                : null,
                            onTap: () => context.go('/g/vets/${vet.id}'),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.go('/g/vets'),
                            child: Text(l.manageVeterinarians),
                          ),
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  int _linkedPetCount(String vetId, List<Pet> pets) {
    return pets.where((p) => p.vetId == vetId).length;
  }
}
