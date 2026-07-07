import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import 'pet_form_info_tooltip.dart';

class PetFormBioSection extends StatelessWidget {
  const PetFormBioSection({
    super.key,
    required this.textController,
    required this.onChanged,
  });

  final TextEditingController textController;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return TextFormField(
      key: const Key('pet_bio_field'),
      controller: textController,
      decoration: InputDecoration(
        labelText: l.petBio,
        alignLabelWithHint: true,
        helperText: 'Personality traits, likes, quirks',
        suffixIcon: PetFormInfoTooltip(
          message:
              'Anything a caregiver should know about your pet\'s temperament or habits',
        ),
      ),
      maxLines: 4,
      maxLength: 500,
      onChanged: onChanged,
    );
  }
}
