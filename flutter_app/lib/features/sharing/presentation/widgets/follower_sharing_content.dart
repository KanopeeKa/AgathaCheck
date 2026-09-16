import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../providers/sharing_providers.dart';

class FollowerSharingContent extends ConsumerWidget {
  const FollowerSharingContent({required this.petId, required this.pet});

  final String petId;
  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.sharedPetFollowerDescription(pet.name),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _confirmStopFollowing(context, ref, l),
            icon: const Icon(Icons.person_remove),
            label: Text(l.stopFollowing),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _confirmHide(context, ref, l),
            icon: const Icon(Icons.visibility_off),
            label: Text(l.hideFromMyPets),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _confirmStopFollowing(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.stopFollowing),
        content: Text(l.stopFollowingConfirm(pet.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await stopFollowingPet(ref, petId);
                if (context.mounted) context.go('/');
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: Text(l.stopFollowing),
          ),
        ],
      ),
    );
  }

  void _confirmHide(BuildContext context, WidgetRef ref, AppLocalizations l) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.hideFromMyPets),
        content: Text(l.hideSharedPetConfirm(pet.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(hiddenSharedPetsProvider.notifier)
                    .hideSharedPet(petId);
                if (context.mounted) context.go('/');
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: Text(l.hideFromMyPets),
          ),
        ],
      ),
    );
  }
}
