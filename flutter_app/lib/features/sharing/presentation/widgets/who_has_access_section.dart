import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../people/application/people_commands.dart';
import '../../../pet_profile/pet_profile.dart';
import '../../domain/entities/household_pet_access.dart';
import '../providers/sharing_providers.dart';

class WhoHasAccessSection extends ConsumerWidget {
  const WhoHasAccessSection({super.key, required this.householdAccess});

  final List<HouseholdPetAccess> householdAccess;

  String? _petIdFromRoute(BuildContext context) {
    final params = GoRouterState.of(context).pathParameters;
    return params['petId'];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (householdAccess.isEmpty) return const SizedBox.shrink();

    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final householdId = householdAccess.first.householdId;
    final householdName = householdAccess.first.householdName;

    final routePetId = _petIdFromRoute(context);
    final pets = ref.watch(petListProvider).valueOrNull ?? const <Pet>[];
    Pet? routePet;
    if (routePetId != null) {
      for (final pet in pets) {
        if (pet.id == routePetId) {
          routePet = pet;
          break;
        }
      }
    }
    final canRemoveFromHousehold =
        routePet != null && !routePet.isShared && routePetId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.whoHasAccessHouseholdTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        if (canRemoveFromHousehold) ...[
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(householdName, style: theme.textTheme.titleSmall),
                  Text(
                    l.whoHasAccessPetInHousehold,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    key: Key('remove_pet_from_household_$routePetId'),
                    onPressed: () => _confirmRemoveFromHousehold(
                      context,
                      ref,
                      l,
                      petId: routePetId!,
                      petName: routePet!.name,
                      householdId: householdId,
                      householdName: householdName,
                    ),
                    child: Text(
                      l.peopleHouseholdRemovePetAction(
                        routePet.name,
                        householdName,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        ...householdAccess.map(
          (row) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(row.displayName),
              subtitle: Text(
                '${row.householdName} · ${row.tierLabel}',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _confirmRemoveFromHousehold(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l, {
    required String petId,
    required String petName,
    required String householdId,
    required String householdName,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.peopleHouseholdRemovePetTitle(petName, householdName)),
        content: Text(l.peopleHouseholdRemovePetBody(petName, householdName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l.peopleHouseholdRemovePetConfirm(petName, householdName),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(peopleCommandsProvider).removeOwnerPetFromHousehold(
            householdId: householdId,
            petId: petId,
          );
      ref.invalidate(petAccessOverviewProvider(petId));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.peopleSaveError)),
        );
      }
    }
  }
}
