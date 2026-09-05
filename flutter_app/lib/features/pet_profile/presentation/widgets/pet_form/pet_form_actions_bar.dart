import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

class PetFormActionsBar extends StatelessWidget {
  const PetFormActionsBar({
    super.key,
    required this.isEditing,
    required this.isLoading,
    required this.isDirty,
    required this.onSave,
    required this.onCancel,
  });

  final bool isEditing;
  final bool isLoading;
  final bool isDirty;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            key: const Key('cancel_pet_button'),
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
            key: const Key('save_pet_button'),
            onPressed: isLoading || !isDirty ? null : onSave,
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
            label: Text(isEditing ? l.petFormSaveChanges : l.savePet),
          ),
        ),
      ],
    );
  }
}

/// Sticky Save/Cancel bar for phone layouts, pinned above the safe area.
class PetFormStickyActionsBar extends StatelessWidget {
  const PetFormStickyActionsBar({
    super.key,
    required this.isEditing,
    required this.isLoading,
    required this.isDirty,
    required this.onSave,
    required this.onCancel,
  });

  final bool isEditing;
  final bool isLoading;
  final bool isDirty;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      key: const Key('pet_form_sticky_actions'),
      elevation: 8,
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: PetFormActionsBar(
            isEditing: isEditing,
            isLoading: isLoading,
            isDirty: isDirty,
            onSave: onSave,
            onCancel: onCancel,
          ),
        ),
      ),
    );
  }
}
