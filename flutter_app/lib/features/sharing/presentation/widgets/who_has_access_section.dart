import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../people/application/people_commands.dart';
import '../../domain/entities/household_pet_access.dart';
import '../providers/sharing_providers.dart';

class WhoHasAccessSection extends ConsumerWidget {
  const WhoHasAccessSection({
    super.key,
    required this.petId,
    required this.petName,
    required this.householdAccess,
    this.canRemoveFromHousehold = false,
  });

  final String petId;
  final String petName;
  final List<HouseholdPetAccess> householdAccess;
  final bool canRemoveFromHousehold;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (householdAccess.isEmpty) return const SizedBox.shrink();

    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final householdId = householdAccess.first.householdId;
    final householdName = householdAccess.first.householdName;

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
                    key: Key('remove_pet_from_household_$petId'),
                    onPressed: () => _confirmRemoveFromHousehold(
                      context,
                      ref,
                      l,
                      householdId: householdId,
                      householdName: householdName,
                    ),
                    child: Text(
                      l.peopleHouseholdRemovePetAction(petName, householdName),
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
            child: Text(l.peopleHouseholdRemovePetConfirm(petName, householdName)),
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
