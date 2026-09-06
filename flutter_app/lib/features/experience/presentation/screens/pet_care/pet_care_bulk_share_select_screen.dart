import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../../pet_profile/domain/entities/pet.dart';
import '../../../../pet_profile/presentation/controllers/pet_list_controller.dart';
import '../../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../widgets/experience_shell_scaffold.dart';
import '../../widgets/pet_care_pets_tile_grid.dart';
import '../../../domain/entities/app_experience.dart';
import 'pet_care_bulk_share.dart';
import 'pet_care_dashboard_helpers.dart';

/// Multi-select screen for bulk-sharing owned guardian pets.
class PetCareBulkShareSelectScreen extends ConsumerStatefulWidget {
  const PetCareBulkShareSelectScreen({super.key});

  @override
  ConsumerState<PetCareBulkShareSelectScreen> createState() =>
      _PetCareBulkShareSelectScreenState();
}

class _PetCareBulkShareSelectScreenState
    extends ConsumerState<PetCareBulkShareSelectScreen> {
  final _controller = PetListController();
  final _selectedPetIds = <String>{};

  List<Pet> _eligiblePets(List<Pet> allPets) {
    return petCareDashboardPersonalPets(allPets, _controller);
  }

  void _toggleSelectAll(List<Pet> eligible) {
    setState(() {
      final allSelected =
          eligible.isNotEmpty &&
          eligible.every((pet) => _selectedPetIds.contains(pet.id));
      if (allSelected) {
        _selectedPetIds.clear();
      } else {
        _selectedPetIds
          ..clear()
          ..addAll(eligible.map((pet) => pet.id));
      }
    });
  }

  Future<void> _shareSelected(BuildContext context, AppLocalizations l) async {
    final pets = ref.read(petListProvider).valueOrNull ?? [];
    final selected = _eligiblePets(pets)
        .where((pet) => _selectedPetIds.contains(pet.id))
        .map((pet) => (id: pet.id, name: pet.name))
        .toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.bulkShareNoneSelected)));
      return;
    }
    await runBulkShareForPets(context, ref, selected);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.bulkShareDone)));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final petListAsync = ref.watch(petListProvider);
    final entriesAsync = ref.watch(healthEntriesNotifierProvider);
    final theme = Theme.of(context);

    return ExperienceShellScaffold(
      experience: AppExperience.petCare,
      currentLocation: GoRouterState.of(context).uri.path,
      screenTitle: l.bulkShare,
      backPath: '/pc/pets',
      child: petListAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(l.failedToLoadPets('$error'))),
        data: (allPets) {
          final eligible = _eligiblePets(allPets);
          final careSummary =
              entriesAsync.hasValue && entriesAsync.valueOrNull != null
              ? PetCareTodayCareSummary.forPets(
                  entries: entriesAsync.valueOrNull!,
                  pets: eligible,
                )
              : null;
          final allSelected =
              eligible.isNotEmpty &&
              eligible.every((pet) => _selectedPetIds.contains(pet.id));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.bulkShareSelectHint,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    TextButton(
                      key: const Key('bulk_share_select_all_toggle'),
                      onPressed: eligible.isEmpty
                          ? null
                          : () => _toggleSelectAll(eligible),
                      child: Text(
                        allSelected ? l.deselectAllPets : l.selectAllPets,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: eligible.isEmpty
                    ? Center(
                        child: Text(
                          l.noPetsYet,
                          style: theme.textTheme.bodyLarge,
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        children: [
                          PetCarePetsTileGrid(
                            pets: eligible,
                            careSummary: careSummary,
                            selectionMode: true,
                            selectedPetIds: _selectedPetIds,
                            onToggleSelection: (pet) {
                              setState(() {
                                if (_selectedPetIds.contains(pet.id)) {
                                  _selectedPetIds.remove(pet.id);
                                } else {
                                  _selectedPetIds.add(pet.id);
                                }
                              });
                            },
                            onPetTap: (_) {},
                          ),
                        ],
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: FilledButton(
                    key: const Key('bulk_share_confirm_button'),
                    onPressed: _selectedPetIds.isEmpty
                        ? null
                        : () => _shareSelected(context, l),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text(
                      l.shareSelectedPetsCount(_selectedPetIds.length),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
