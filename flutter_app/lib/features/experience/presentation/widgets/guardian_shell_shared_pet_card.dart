import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../../pet_profile/presentation/widgets/pet_card.dart';
import '../../../sharing/presentation/providers/sharing_providers.dart';

/// Dismissible shared-pet card for the guardian shell home.
class GuardianShellSharedPetCard extends StatelessWidget {
  const GuardianShellSharedPetCard({
    super.key,
    required this.pet,
    required this.l,
    required this.theme,
    required this.ref,
    required this.parentContext,
    this.child,
  });

  final Pet pet;
  final AppLocalizations l;
  final ThemeData theme;
  final WidgetRef ref;
  final BuildContext parentContext;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('hide_shell_shared_${pet.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.hideSharedPet),
            const SizedBox(width: 8),
            Icon(
              Icons.visibility_off,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: parentContext,
          builder: (ctx) => AlertDialog(
            title: Text(l.hideSharedPet),
            content: Text(l.hideSharedPetConfirm(pet.name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.hide),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await ref
              .read(hiddenSharedPetsProvider.notifier)
              .hideSharedPet(pet.id);
          if (parentContext.mounted) {
            ScaffoldMessenger.of(
              parentContext,
            ).showSnackBar(SnackBar(content: Text(l.petHidden(pet.name))));
          }
        }
        return false;
      },
      child:
          child ?? PetCard(pet: pet, onTap: () => context.go('/pet/${pet.id}')),
    );
  }
}
