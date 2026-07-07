import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../controllers/pet_form_controller.dart';

/// Weight field for edit mode, or optional initial-weight entry when adding a pet.
class PetFormWeightSection extends StatelessWidget {
  const PetFormWeightSection({
    super.key,
    required this.isEditing,
    required this.showWeightInput,
    required this.weightController,
    required this.newWeightController,
    required this.controller,
    required this.onShowWeightInput,
    required this.onHideWeightInput,
  });

  final bool isEditing;
  final bool showWeightInput;
  final TextEditingController weightController;
  final TextEditingController newWeightController;
  final PetFormController controller;
  final VoidCallback onShowWeightInput;
  final VoidCallback onHideWeightInput;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    if (isEditing) {
      return TextFormField(
        key: const Key('pet_weight_field'),
        controller: weightController,
        decoration: InputDecoration(labelText: l.weightWithUnit('kg')),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (value) =>
            controller.state = controller.state.copyWith(weight: value),
        validator: (value) {
          if (value != null && value.isNotEmpty) {
            final num = double.tryParse(value);
            if (num == null || num < 0) {
              return 'Invalid weight';
            }
          }
          return null;
        },
      );
    }

    if (showWeightInput) {
      return TextFormField(
        key: const Key('pet_initial_weight_field'),
        controller: newWeightController,
        decoration: InputDecoration(
          labelText: l.weightWithUnit('kg'),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close, size: 18),
            tooltip: 'Remove weight entry',
            onPressed: onHideWeightInput,
          ),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        autofocus: true,
        onChanged: controller.setNewWeight,
        validator: (value) {
          if (value != null && value.isNotEmpty) {
            final num = double.tryParse(value);
            if (num == null || num <= 0) {
              return 'Invalid weight';
            }
          }
          return null;
        },
      );
    }

    return Tooltip(
      message: 'Add initial weight entry',
      child: OutlinedButton.icon(
        key: const Key('add_weight_entry_button'),
        onPressed: onShowWeightInput,
        icon: const Icon(Icons.monitor_weight_outlined, size: 18),
        label: Text(l.addWeightEntry),
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
      ),
    );
  }
}
