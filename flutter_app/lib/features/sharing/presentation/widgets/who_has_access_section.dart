import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../auth/auth.dart';
import '../../domain/entities/household_pet_access.dart';
import '../providers/sharing_providers.dart';
import 'owner_sharing_content.dart';

/// When set, shows a control to remove the record owner's pet from a household.
class RemovePetFromHouseholdOffer {
  const RemovePetFromHouseholdOffer({
    required this.petId,
    required this.petName,
    required this.householdId,
    required this.householdName,
    required this.onConfirmRemove,
  });

  final String petId;
  final String petName;
  final String householdId;
  final String householdName;
  final Future<void> Function() onConfirmRemove;
}

class WhoHasAccessSection extends ConsumerWidget {
  const WhoHasAccessSection({
    super.key,
    required this.householdAccess,
    this.removePetFromHousehold,
  });

  final List<HouseholdPetAccess> householdAccess;
  final RemovePetFromHouseholdOffer? removePetFromHousehold;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (householdAccess.isEmpty) return const SizedBox.shrink();

    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final householdId = householdAccess.first.householdId;
    final householdName = householdAccess.first.householdName;
    var removeOffer = removePetFromHousehold;
    if (removeOffer == null) {
      final owner = context.findAncestorWidgetOfExactType<OwnerSharingContent>();
      if (owner != null &&
          !owner.pet.isShared &&
          householdAccess.isNotEmpty) {
        final row = householdAccess.first;
        removeOffer = RemovePetFromHouseholdOffer(
          petId: owner.petId,
          petName: owner.pet.name,
          householdId: row.householdId,
          householdName: row.householdName,
          onConfirmRemove: () async {
            final token =
                await ref.read(authProvider.notifier).getValidAccessToken();
            if (token == null) return;
            await ref.read(sharingRepositoryProvider).removeOwnerPetFromHousehold(
                  householdId: row.householdId,
                  petId: owner.petId,
                  token: token,
                );
            ref.invalidate(petAccessOverviewProvider(owner.petId));
          },
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.whoHasAccessHouseholdTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        if (removeOffer != null && removeOffer.householdId == householdId) ...[
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
                    key: Key('remove_pet_from_household_${removeOffer.petId}'),
                    onPressed: () =>
                        _confirmRemoveFromHousehold(context, l, removeOffer!),
                    child: Text(l.peopleHouseholdRemovePetAction(removeOffer.petName)),
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
    AppLocalizations l,
    RemovePetFromHouseholdOffer offer,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l.peopleHouseholdRemovePetTitle(offer.petName, offer.householdName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.removeAccess),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await offer.onConfirmRemove();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.peopleSaveError)));
      }
    }
  }
}
