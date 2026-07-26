import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/dashboard_section.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_profile/domain/entities/pet.dart';
import '../../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../vet/presentation/providers/vet_providers.dart';
import '../../../../vet/presentation/widgets/vet_compact_row.dart';

/// My Vets dashboard section — compact scannable rows, uncapped.
class GuardianMyVetsSection extends ConsumerWidget {
  const GuardianMyVetsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    final vetListAsync = ref.watch(vetListProvider);
    final pets = ref.watch(petListProvider).valueOrNull ?? [];

    return DashboardSection(
      title: l.myVets,
      headerAction: TextButton(
        onPressed: () => context.go('/g/vets/add'),
        child: Text(l.addVet),
      ),
      previewBuilder: (ctx) {
        if (auth.accessToken == null) {
          return const SizedBox(
            height: 24,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        return vetListAsync.when(
          loading: () => const SizedBox(
            height: 24,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, __) => TextButton(
            onPressed: () => ref.read(vetListProvider.notifier).refresh(),
            child: Text(l.retry),
          ),
          data: (vets) {
            if (vets.isEmpty) {
              return Text(
                l.addVetFirst,
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              );
            }

            return Column(
              children: vets
                  .map(
                    (vet) => VetCompactRow(
                      vet: vet,
                      linkedPetCount: _linkedPetCount(vet.id, pets),
                      onTap: () => context.go('/g/vets/${vet.id}'),
                    ),
                  )
                  .toList(),
            );
          },
        );
      },
      endLink: DashboardSectionLink(
        label: l.allVets,
        onPressed: () => context.go('/g/vets'),
      ),
    );
  }

  int _linkedPetCount(String vetId, List<Pet> pets) {
    return pets.where((p) => p.vetId == vetId).length;
  }
}
