import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../providers/pet_providers.dart';

Future<void> confirmDeletePet({
  required BuildContext context,
  required WidgetRef ref,
  required String petId,
  required ValueChanged<bool> onLoadingChanged,
}) async {
  final l = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.deletePet),
      content: Text(l.deletePetConfirm('')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l.delete),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    onLoadingChanged(true);
    try {
      await ref.read(petListProvider.notifier).deletePet(petId);
      if (context.mounted) context.go('/');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete pet: $e')));
      }
    } finally {
      if (context.mounted) onLoadingChanged(false);
    }
  }
}

Future<void> confirmPassedAway({
  required BuildContext context,
  required WidgetRef ref,
  required String petId,
  required ValueChanged<bool> onLoadingChanged,
}) async {
  final l = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.passedAway),
      content: const Text(
        'Are you sure you want to mark this pet as passed away?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l.ok),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    onLoadingChanged(true);
    try {
      await ref.read(petListProvider.notifier).markPassedAway(petId);
      if (context.mounted) context.go('/');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update pet: $e')));
      }
    } finally {
      if (context.mounted) onLoadingChanged(false);
    }
  }
}
