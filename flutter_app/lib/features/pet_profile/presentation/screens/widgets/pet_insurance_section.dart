import 'package:flutter/material.dart';

class PetInsuranceSection extends StatelessWidget {
  final TextEditingController controller;

  const PetInsuranceSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: const Key('pet_insurance_field'),
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Insurance',
        helperText: 'Insurance provider or policy',
      ),
    );
  }
}
