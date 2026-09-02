import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/constants.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../organization/presentation/providers/organization_providers.dart';
import '../../../../sharing/presentation/providers/sharing_providers.dart';

class PendingSharesSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingSharesProvider);
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return pendingAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (pendingShares) {
        if (pendingShares.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.share, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    l.pendingShares,
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
                      '${pendingShares.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...pendingShares.map((share) => PendingShareCard(share: share)),
            ],
          ),
        );
      },
    );
  }
}

class PendingShareCard extends ConsumerWidget {
  const PendingShareCard({required this.share});

  final PendingShare share;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final petColor = share.petColorValue != null
        ? Color(share.petColorValue!)
        : theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.primary.withAlpha(80)),
        ),
        color: theme.colorScheme.primaryContainer.withAlpha(40),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: petColor.withAlpha(40),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: AppConstants.speciesIconWidget(
                        share.petSpecies,
                        size: 22,
                        color: petColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          share.petName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l.petSharedWithYou(
                            share.primaryHolderName.isNotEmpty
                                ? share.primaryHolderName
                                : 'Someone',
                            share.petName,
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () async {
                      try {
                        await ref
                            .read(pendingSharesProvider.notifier)
                            .declineShare(share.petId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l.shareDeclined)),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      }
                    },
                    child: Text(l.declineShare),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () =>
                        _showAcceptShareDialog(context, ref, share, l),
                    child: Text(l.acceptShare),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAcceptShareDialog(
    BuildContext context,
    WidgetRef ref,
    PendingShare share,
    AppLocalizations l,
  ) {
    final orgsAsync = ref.read(organizationListProvider);
    final orgs = orgsAsync.valueOrNull ?? [];

    if (orgs.isEmpty) {
      _doAcceptShare(context, ref, share.petId, null, l);
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.acceptShareTo,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  l.acceptShareToHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(l.myPets),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _doAcceptShare(context, ref, share.petId, null, l);
                  },
                ),
                const Divider(),
                ...orgs.map(
                  (org) => ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.business)),
                    title: Text(org.name),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _doAcceptShare(context, ref, share.petId, org.id, l);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _doAcceptShare(
    BuildContext context,
    WidgetRef ref,
    String petId,
    String? orgId,
    AppLocalizations l,
  ) async {
    try {
      await ref
          .read(pendingSharesProvider.notifier)
          .acceptShare(petId, organizationId: orgId);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.shareAccepted)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}
