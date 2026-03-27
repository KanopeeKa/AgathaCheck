import 'package:flutter/material.dart';

class PetBioSection extends StatelessWidget {
  final TextEditingController controller;

  const PetBioSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: const Key('pet_bio_field'),
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Bio',
        helperText: 'A few words about your pet',
      ),
      maxLines: 3,
    );
  }
}
