import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import 'pet_form_labeled_field.dart';

class PetFormBioSection extends StatelessWidget {
  const PetFormBioSection({
    super.key,
    required this.textController,
    required this.onChanged,
    this.petName = '',
  });

  final TextEditingController textController;
  final ValueChanged<String> onChanged;
  final String petName;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final label = petName.trim().isEmpty
        ? l.petBio
        : l.aboutPetNamed(petName.trim());

    return PetFormLabeledField(
      label: label,
      child: TextFormField(
        key: const Key('pet_bio_field'),
        controller: textController,
        decoration: const InputDecoration(alignLabelWithHint: true),
        maxLines: 4,
        maxLength: 500,
        buildCounter:
            (context, {required currentLength, required isFocused, maxLength}) {
              return Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$currentLength / $maxLength',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            },
        onChanged: onChanged,
      ),
    );
  }
}
