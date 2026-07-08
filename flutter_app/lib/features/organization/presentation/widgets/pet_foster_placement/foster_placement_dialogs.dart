import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/foster_parent.dart';
import '../../../domain/entities/foster_placement.dart';
import '../../providers/foster_placements_providers.dart';
import '../../providers/organization_providers.dart';

/// Dialog and confirmation flows for foster placement actions on a pet.
class FosterPlacementDialogs {
  FosterPlacementDialogs._();

  static Future<void> showStartDialog({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l,
    required String orgId,
    required String petId,
    required String petName,
  }) async {
    final fosterParents = await ref.read(orgFosterParentsProvider(orgId).future);
    final memberParents = fosterParents
        .where((p) => p.isMember && p.userId != null && p.userId!.isNotEmpty)
        .toList();
    if (!context.mounted) return;
    if (memberParents.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.noFosterParentsWithAccounts)));
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
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.displayName),
                      ),
                    )
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.fosterPlacementStarted)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      notesController.dispose();
    }
  }

  static Future<void> showDirectAdoptDialog({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l,
    required String orgId,
    required String petId,
    required String petName,
  }) async {
    final fosterParents = await ref.read(orgFosterParentsProvider(orgId).future);
    final memberParents = fosterParents
        .where((p) => p.isMember && p.userId != null && p.userId!.isNotEmpty)
        .toList();
    if (!context.mounted) return;
    if (memberParents.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.noFosterParentsWithAccounts)));
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
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.displayName),
                      ),
                    )
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
      await ref
          .read(petFosterPlacementProvider((orgId, petId)).notifier)
          .directAdopt(
            fosterUserId: selected!.userId!,
            adoptionConditions: conditionsController.text.trim(),
            notes: notesController.text.trim(),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.adoptionStarted)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      conditionsController.dispose();
      notesController.dispose();
    }
  }

  static Future<void> showStartAdoptionDialog({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l,
    required String orgId,
    required String petId,
    required String petName,
    required FosterPlacement placement,
  }) async {
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.adoptionStarted)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      conditionsController.dispose();
    }
  }

  static Future<void> completeConditions({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l,
    required String orgId,
    required String petId,
    required FosterPlacement placement,
  }) async {
    try {
      await ref
          .read(petFosterPlacementProvider((orgId, petId)).notifier)
          .completeAdoptionConditions(placement.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.adoptionConditionsMet)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  static Future<void> confirmCancelAdoption({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l,
    required String orgId,
    required String petId,
    required String petName,
    required FosterPlacement placement,
  }) async {
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.adoptionCancelled)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  static Future<void> confirmEnd({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l,
    required String orgId,
    required String petId,
    required String petName,
    required FosterPlacement placement,
  }) async {
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.fosterPlacementEnded)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}
