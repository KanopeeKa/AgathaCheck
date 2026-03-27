import 'package:flutter/material.dart';

class PetChipSection extends StatelessWidget {
  final TextEditingController controller;
  final bool chipDismissed;
  final ValueChanged<bool> onDismissedChanged;

  const PetChipSection({
    super.key,
    required this.controller,
    required this.chipDismissed,
    required this.onDismissedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            key: const Key('pet_chip_field'),
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Microchip ID',
              helperText: 'If your pet is microchipped',
            ),
          ),
        ),
        Checkbox(
          value: chipDismissed,
          onChanged: (v) => onDismissedChanged(v ?? false),
        ),
        const Text('No chip'),
      ],
    );
  }
}
