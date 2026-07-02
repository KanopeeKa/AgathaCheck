import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/foster_parent.dart';
import '../../domain/entities/foster_placement.dart';
import '../providers/foster_placements_providers.dart';
import '../providers/organization_providers.dart';

class PetFosterPlacementSection extends ConsumerWidget {
  const PetFosterPlacementSection({
    super.key,
    required this.orgId,
    required this.petId,
    required this.petName,
  });

  final String orgId;
  final String petId;
  final String petName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final placementAsync = ref.watch(petFosterPlacementProvider((orgId, petId)));

    return Card(
      color: AppTheme.orgBlueDarker,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.fosterPlacement,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            placementAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(),
              ),
              error: (e, _) => Text('$e',
                  style: TextStyle(color: theme.colorScheme.error)),
              data: (state) {
                final placement = state.placement;
                if (state.isNotInFoster) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.fosterPlacementNotInFoster,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: const Key('start_foster_placement_button'),
                        onPressed: () => _showStartDialog(context, ref, l),
                        icon: const Icon(Icons.home_work_outlined, size: 18),
                        label: Text(l.startFosterPlacement),
                      ),
                    ],
                  );
                }

                final fosterLabel = placement!.fosterName.isNotEmpty
                    ? placement.fosterName
                    : placement.fosterEmail;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.fosterPlacementStatus(_statusLabel(l, placement))),
                    const SizedBox(height: 4),
                    Text(l.fosterPlacementAssignedTo(fosterLabel)),
                    if (placement.startDate != null) ...[
                      const SizedBox(height: 4),
                      Text(l.fosterPlacementStartDate(
                        DateFormat.yMMMd().format(placement.startDate!),
                      )),
                    ],
                    if (placement.isInProgress) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: const Key('end_foster_placement_button'),
                        onPressed: () => _confirmEnd(context, ref, l, placement),
                        icon: const Icon(Icons.event_busy, size: 18),
                        label: Text(l.endFosterPlacement),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(AppLocalizations l, FosterPlacement placement) {
    if (placement.isPending) return l.fosterPlacementPending;
    if (placement.isInProgress) return l.fosterPlacementInProgress;
    return l.fosterPlacementNotInFoster;
  }

  Future<void> _showStartDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
  ) async {
    final fosterParents = await ref.read(orgFosterParentsProvider(orgId).future);
    final memberParents = fosterParents
        .where((p) => p.isMember && p.userId != null && p.userId!.isNotEmpty)
        .toList();
    if (!context.mounted) return;
    if (memberParents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.noFosterParentsWithAccounts)),
      );
      return;
    }

    FosterParent? selected = memberParents.first;
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l.startFosterPlacement),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.startFosterPlacementDescription(petName)),
              const SizedBox(height: 12),
              DropdownButtonFormField<FosterParent>(
                value: selected,
                decoration: InputDecoration(labelText: l.fosterParents),
                items: memberParents
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.displayName),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => selected = value),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                decoration: InputDecoration(labelText: l.notes),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.startFosterPlacement),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || selected?.userId == null) {
      notesController.dispose();
      return;
    }

    try {
      await ref
          .read(petFosterPlacementProvider((orgId, petId)).notifier)
          .startPlacement(
            fosterUserId: selected!.userId!,
            notes: notesController.text.trim(),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.fosterPlacementStarted)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      notesController.dispose();
    }
  }

  Future<void> _confirmEnd(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
    FosterPlacement placement,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.endFosterPlacement),
        content: Text(l.endFosterPlacementConfirm(petName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.endFosterPlacement),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(petFosterPlacementProvider((orgId, petId)).notifier)
          .endPlacement(placement.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.fosterPlacementEnded)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }
}
