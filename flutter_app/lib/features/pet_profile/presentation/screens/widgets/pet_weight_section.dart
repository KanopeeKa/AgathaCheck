import 'package:flutter/material.dart';

class PetWeightSection extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? helperText;
  final String? Function(String?)? validator;

  const PetWeightSection({
    super.key,
    required this.controller,
    required this.label,
    this.helperText,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: const Key('pet_weight_field'),
      controller: controller,
      decoration: InputDecoration(labelText: label, helperText: helperText),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: validator,
    );
  }
}
