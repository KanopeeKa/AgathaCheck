import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Cancel + Save action row for harmonised create/edit forms.
class AppFormActionsBar extends StatelessWidget {
  const AppFormActionsBar({
    super.key,
    required this.isLoading,
    required this.isDirty,
    required this.onSave,
    required this.onCancel,
    required this.saveLabel,
    this.cancelKey,
    this.saveKey,
    this.requireDirtyToSave = true,
  });

  final bool isLoading;
  final bool isDirty;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final String saveLabel;
  final Key? cancelKey;
  final Key? saveKey;
  final bool requireDirtyToSave;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final canSave = !isLoading && (!requireDirtyToSave || isDirty);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            key: cancelKey,
            onPressed: isLoading ? null : onCancel,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(l.cancel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            key: saveKey,
            onPressed: canSave ? onSave : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(saveLabel),
          ),
        ),
      ],
    );
  }
}

/// Sticky Save/Cancel bar for phone layouts, pinned above the safe area.
class AppFormStickyActionsBar extends StatelessWidget {
  const AppFormStickyActionsBar({
    super.key,
    required this.stickyKey,
    required this.isLoading,
    required this.isDirty,
    required this.onSave,
    required this.onCancel,
    required this.saveLabel,
    this.cancelKey,
    this.saveKey,
    this.requireDirtyToSave = true,
  });

  final Key stickyKey;
  final bool isLoading;
  final bool isDirty;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final String saveLabel;
  final Key? cancelKey;
  final Key? saveKey;
  final bool requireDirtyToSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      key: stickyKey,
      elevation: 8,
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: AppFormActionsBar(
            isLoading: isLoading,
            isDirty: isDirty,
            onSave: onSave,
            onCancel: onCancel,
            saveLabel: saveLabel,
            cancelKey: cancelKey,
            saveKey: saveKey,
            requireDirtyToSave: requireDirtyToSave,
          ),
        ),
      ),
    );
  }
}
