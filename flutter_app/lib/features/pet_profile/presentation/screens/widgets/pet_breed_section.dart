import 'package:flutter/material.dart';

class PetBreedSection extends StatelessWidget {
  final TextEditingController controller;

  const PetBreedSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: const Key('pet_breed_field'),
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Breed',
        helperText: 'Breed or variety, if known',
        suffixIcon: Icon(Icons.info_outline),
      ),
    );
  }
}
