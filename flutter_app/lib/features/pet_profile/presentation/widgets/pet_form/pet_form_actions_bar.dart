import 'package:flutter/material.dart';

import '../../../../../core/widgets/form/app_form_actions_bar.dart';
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
    return AppFormActionsBar(
      isLoading: isLoading,
      isDirty: isDirty,
      onSave: onSave,
      onCancel: onCancel,
      saveLabel: isEditing ? l.petFormSaveChanges : l.savePet,
      cancelKey: const Key('cancel_pet_button'),
      saveKey: const Key('save_pet_button'),
    );
  }
}

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
    final l = AppLocalizations.of(context)!;
    return AppFormStickyActionsBar(
      stickyKey: const Key('pet_form_sticky_actions'),
      isLoading: isLoading,
      isDirty: isDirty,
      onSave: onSave,
      onCancel: onCancel,
      saveLabel: isEditing ? l.petFormSaveChanges : l.savePet,
      cancelKey: const Key('cancel_pet_button'),
      saveKey: const Key('save_pet_button'),
    );
  }
}
