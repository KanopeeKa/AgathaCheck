import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/foster_parent.dart';
import '../../domain/entities/foster_placement.dart';
import '../providers/foster_placements_providers.dart';
import '../providers/organization_providers.dart';
import '../utils/foster_placement_display.dart';

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
    final colorScheme = theme.colorScheme;
    final placementAsync = ref.watch(petFosterPlacementProvider((orgId, petId)));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: placementAsync.when(
          loading: () => ExpansionTile(
            leading: Icon(Icons.home_work_outlined, color: colorScheme.primary),
            title: Text(
              l.fosterPlacement,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            children: const [
              Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
          error: (e, _) => ExpansionTile(
            leading: Icon(Icons.home_work_outlined, color: colorScheme.primary),
            title: Text(
              l.fosterPlacement,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '$e',
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            ],
          ),
          data: (state) {
            final placement = state.placement;
            final fosterLabel = placement != null &&
                    (placement.fosterName.isNotEmpty ||
                        placement.fosterEmail.isNotEmpty)
                ? (placement.fosterName.isNotEmpty
                    ? placement.fosterName
                    : placement.fosterEmail)
                : null;

            return ExpansionTile(
              leading:
                  Icon(Icons.home_work_outlined, color: colorScheme.primary),
              title: Text(
                l.fosterPlacement,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                fosterPlacementSummary(
                  l,
                  status: state.isNotInFoster ? null : placement?.status,
                  fosterName: fosterLabel,
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: state.isNotInFoster
                      ? _NotInFosterContent(
                          l: l,
                          theme: theme,
                          onStart: () => _showStartDialog(context, ref, l),
                          onDirectAdopt: () =>
                              _showDirectAdoptDialog(context, ref, l),
                        )
                      : _ActivePlacementContent(
                          l: l,
                          theme: theme,
                          placement: placement!,
                          onStartAdoption: () => _showStartAdoptionDialog(
                            context,
                            ref,
                            l,
                            placement,
                          ),
                          onEnd: () =>
                              _confirmEnd(context, ref, l, placement),
                          onCompleteConditions: () => _completeConditions(
                            context,
                            ref,
                            l,
                            placement,
                          ),
                          onCancelAdoption: () => _confirmCancelAdoption(
                            context,
                            ref,
                            l,
                            placement,
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
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

  Future<void> _showDirectAdoptDialog(
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
    final conditionsController = TextEditingController();
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l.directAdopt),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.directAdoptDescription(petName)),
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
                controller: conditionsController,
                decoration: InputDecoration(
                  labelText: l.adoptionConditions,
                  hintText: l.adoptionConditionsHint,
                ),
                maxLines: 2,
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
              child: Text(l.directAdopt),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || selected?.userId == null) {
      conditionsController.dispose();
      notesController.dispose();
      return;
    }

    try {
      await ref.read(petFosterPlacementProvider((orgId, petId)).notifier).directAdopt(
            fosterUserId: selected!.userId!,
            adoptionConditions: conditionsController.text.trim(),
            notes: notesController.text.trim(),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.adoptionStarted)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      conditionsController.dispose();
      notesController.dispose();
    }
  }

  Future<void> _showStartAdoptionDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
    FosterPlacement placement,
  ) async {
    final conditionsController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.startAdoption),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.startAdoptionDescription(petName)),
            const SizedBox(height: 12),
            TextField(
              controller: conditionsController,
              decoration: InputDecoration(
                labelText: l.adoptionConditions,
                hintText: l.adoptionConditionsHint,
              ),
              maxLines: 3,
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
            child: Text(l.startAdoption),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      conditionsController.dispose();
      return;
    }

    try {
      await ref
          .read(petFosterPlacementProvider((orgId, petId)).notifier)
          .startAdoption(
            placement.id,
            adoptionConditions: conditionsController.text.trim(),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.adoptionStarted)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      conditionsController.dispose();
    }
  }

  Future<void> _completeConditions(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
    FosterPlacement placement,
  ) async {
    try {
      await ref
          .read(petFosterPlacementProvider((orgId, petId)).notifier)
          .completeAdoptionConditions(placement.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.adoptionConditionsMet)),
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

  Future<void> _confirmCancelAdoption(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
    FosterPlacement placement,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.cancelAdoption),
        content: Text(l.cancelAdoptionConfirm(petName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.cancelAdoption),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(petFosterPlacementProvider((orgId, petId)).notifier)
          .cancelAdoption(placement.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.adoptionCancelled)),
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

class _NotInFosterContent extends StatelessWidget {
  const _NotInFosterContent({
    required this.l,
    required this.theme,
    required this.onStart,
    required this.onDirectAdopt,
  });

  final AppLocalizations l;
  final ThemeData theme;
  final VoidCallback onStart;
  final VoidCallback onDirectAdopt;

  @override
  Widget build(BuildContext context) {
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
          onPressed: onStart,
          icon: const Icon(Icons.home_work_outlined, size: 18),
          label: Text(l.startFosterPlacement),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('direct_adopt_button'),
          onPressed: onDirectAdopt,
          icon: const Icon(Icons.favorite_border, size: 18),
          label: Text(l.directAdopt),
        ),
      ],
    );
  }
}

class _ActivePlacementContent extends StatelessWidget {
  const _ActivePlacementContent({
    required this.l,
    required this.theme,
    required this.placement,
    required this.onStartAdoption,
    required this.onEnd,
    required this.onCompleteConditions,
    required this.onCancelAdoption,
  });

  final AppLocalizations l;
  final ThemeData theme;
  final FosterPlacement placement;
  final VoidCallback onStartAdoption;
  final VoidCallback onEnd;
  final VoidCallback onCompleteConditions;
  final VoidCallback onCancelAdoption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (placement.startDate != null) ...[
          Text(l.fosterPlacementStartDate(
            DateFormat.yMMMd().format(placement.startDate!),
          )),
          const SizedBox(height: 8),
        ],
        if (placement.adoptionConditions.isNotEmpty) ...[
          Text(
            l.adoptionConditions,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(placement.adoptionConditions),
          const SizedBox(height: 8),
        ],
        if (placement.isInProgress) ...[
          OutlinedButton.icon(
            key: const Key('start_adoption_button'),
            onPressed: onStartAdoption,
            icon: const Icon(Icons.favorite_border, size: 18),
            label: Text(l.startAdoption),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('end_foster_placement_button'),
            onPressed: onEnd,
            icon: const Icon(Icons.event_busy, size: 18),
            label: Text(l.endFosterPlacement),
          ),
        ],
        if (placement.isPendingConditions) ...[
          OutlinedButton.icon(
            key: const Key('complete_adoption_conditions_button'),
            onPressed: onCompleteConditions,
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: Text(l.markAdoptionConditionsMet),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onCancelAdoption,
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: Text(l.cancelAdoption),
          ),
        ],
        if (placement.isWaitingAdoption) ...[
          Text(
            l.waitingAdoptionConfirmation,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onCancelAdoption,
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: Text(l.cancelAdoption),
          ),
        ],
      ],
    );
  }
}
