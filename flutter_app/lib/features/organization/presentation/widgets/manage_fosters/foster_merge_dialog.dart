import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/foster_parent.dart';
import '../../providers/organization_providers.dart';

Future<void> showFosterMergeDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String orgId,
  required FosterParent parent,
}) async {
  final l = AppLocalizations.of(context)!;
  final email = parent.email?.trim() ?? '';
  if (email.isEmpty) return;

  List<FosterMergeSuggestion> suggestions;
  try {
    suggestions = await ref
        .read(orgFosterParentsProvider(orgId).notifier)
        .fetchMergeSuggestions(email);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
    return;
  }

  if (!context.mounted) return;
  if (suggestions.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.manageFostersMergeNoMatch)));
    return;
  }

  FosterMergeSuggestion? selected = suggestions.first;
  if (suggestions.length > 1) {
    selected = await showDialog<FosterMergeSuggestion>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.manageFostersMergeSelectAccount),
        content: RadioGroup<FosterMergeSuggestion>(
          groupValue: selected,
          onChanged: (value) => Navigator.pop(ctx, value),
          child: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                return RadioListTile<FosterMergeSuggestion>(
                  value: suggestion,
                  title: Text(suggestion.displayName),
                  subtitle: Text(suggestion.email),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  if (!context.mounted || selected == null) return;
  final target = selected;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.manageFostersMergeConfirmTitle),
      content: Text(
        l.manageFostersMergeConfirmBody(parent.displayName, target.displayName),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l.manageFostersMergeConfirmAction),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  try {
    await ref
        .read(orgFosterParentsProvider(orgId).notifier)
        .mergeIntoRegisteredAccount(
          fosterParentId: parent.id,
          targetUserId: target.userId,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.manageFostersMergeSuccess)));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}
