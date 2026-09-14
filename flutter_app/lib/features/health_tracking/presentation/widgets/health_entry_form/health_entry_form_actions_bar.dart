import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/form/app_form_actions_bar.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../controllers/health_entry_form_controller.dart';
import '../../controllers/health_entry_form_state.dart';

class HealthEntryFormActionsBar extends ConsumerWidget {
  const HealthEntryFormActionsBar({
    super.key,
    required this.params,
    required this.isLoading,
    required this.onSave,
    required this.onCancel,
  });

  final HealthEntryFormParams params;
  final bool isLoading;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final form = ref.watch(healthEntryFormControllerProvider(params));
    final controller = ref.read(healthEntryFormControllerProvider(params).notifier);

    final saveLabel = form.isEdit
        ? l.healthEntryFormSaveChanges
        : form.selectedPetIds.length > 1
        ? l.addEntryForPets(form.selectedPetIds.length)
        : l.addEntry;

    return AppFormActionsBar(
      isLoading: isLoading,
      isDirty: form.isEdit ? controller.isDirty : true,
      onSave: onSave,
      onCancel: onCancel,
      saveLabel: saveLabel,
      cancelKey: const Key('cancel_health_entry_button'),
      saveKey: const Key('save_health_entry_button'),
      requireDirtyToSave: form.isEdit,
    );
  }
}

class HealthEntryFormStickyActionsBar extends ConsumerWidget {
  const HealthEntryFormStickyActionsBar({
    super.key,
    required this.params,
    required this.isLoading,
    required this.onSave,
    required this.onCancel,
  });

  final HealthEntryFormParams params;
  final bool isLoading;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final form = ref.watch(healthEntryFormControllerProvider(params));
    final controller = ref.read(healthEntryFormControllerProvider(params).notifier);

    final saveLabel = form.isEdit
        ? l.healthEntryFormSaveChanges
        : form.selectedPetIds.length > 1
        ? l.addEntryForPets(form.selectedPetIds.length)
        : l.addEntry;

    return AppFormStickyActionsBar(
      stickyKey: const Key('health_entry_form_sticky_actions'),
      isLoading: isLoading,
      isDirty: form.isEdit ? controller.isDirty : true,
      onSave: onSave,
      onCancel: onCancel,
      saveLabel: saveLabel,
      cancelKey: const Key('cancel_health_entry_button'),
      saveKey: const Key('save_health_entry_button'),
      requireDirtyToSave: form.isEdit,
    );
  }
}
