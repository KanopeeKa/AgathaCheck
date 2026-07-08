import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../organization/domain/entities/custody_transfer.dart';
import '../../../../organization/presentation/providers/organization_providers.dart';

class PendingCustodyTransfersSection extends ConsumerWidget {
  const PendingCustodyTransfersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingCustodyTransfersProvider);
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return pendingAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (transfers) {
        if (transfers.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.swap_horiz,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l.pendingCustodyTransfers,
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
                      '${transfers.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...transfers.map(
                (transfer) => PendingCustodyTransferCard(transfer: transfer),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PendingCustodyTransferCard extends ConsumerWidget {
  const PendingCustodyTransferCard({super.key, required this.transfer});

  final CustodyTransfer transfer;

  String _kindLabel(AppLocalizations l) {
    if (transfer.isOrgToOrg) return l.custodyTransferKindOrgToOrg;
    if (transfer.isReturnToOrg) return l.custodyTransferKindReturn;
    return l.custodyTransferKindIndividual;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final petLabel = transfer.petName?.isNotEmpty == true
        ? transfer.petName!
        : transfer.petId;

    return Card(
      key: Key('pending_custody_${transfer.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              petLabel,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _kindLabel(l),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () async {
                    try {
                      await ref
                          .read(pendingCustodyTransfersProvider.notifier)
                          .cancel(transfer.id);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('$e')));
                      }
                    }
                  },
                  child: Text(l.cancel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: Key('accept_custody_${transfer.id}'),
                  onPressed: () async {
                    try {
                      await ref
                          .read(pendingCustodyTransfersProvider.notifier)
                          .accept(transfer.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l.custodyTransferAccepted)),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('$e')));
                      }
                    }
                  },
                  child: Text(l.acceptCustodyTransfer),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
