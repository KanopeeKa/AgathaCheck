import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/shell_return_navigation.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../organization/domain/entities/foster_placement.dart';
import '../../../../organization/presentation/providers/foster_placements_providers.dart';

class PendingAdoptionPlacementsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingAdoptionPlacementsProvider);
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return pendingAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (placements) {
        if (placements.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l.pendingAdoptionConfirmations,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${placements.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...placements.map(
                (placement) =>
                    PendingAdoptionPlacementCard(placement: placement),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PendingAdoptionPlacementCard extends ConsumerWidget {
  const PendingAdoptionPlacementCard({required this.placement});

  final FosterPlacement placement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final orgLabel = placement.organizationName.isNotEmpty
        ? placement.organizationName
        : l.organizations;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              placement.petName,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.fosterPlacementInviteFrom(orgLabel),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.confirmAdoptionDescription(placement.petName),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton(
                  key: Key('confirm_adoption_${placement.id}'),
                  onPressed: () async {
                    try {
                      await ref
                          .read(pendingAdoptionPlacementsProvider.notifier)
                          .confirm(placement.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l.adoptionConfirmed)),
                        );
                        openPetDetail(context, placement.petId);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('$e')));
                      }
                    }
                  },
                  child: Text(l.confirmAdoption),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
