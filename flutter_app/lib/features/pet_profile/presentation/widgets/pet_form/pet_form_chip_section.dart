import 'package:flutter/material.dart';

import '../../../../../core/widgets/form/app_form_info_button.dart';
import '../../../../../l10n/app_localizations.dart';

class PetFormChipSection extends StatelessWidget {
  const PetFormChipSection({
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
      key: const Key('pet_chip_id_field'),
      controller: textController,
      decoration: InputDecoration(
        labelText: l.idMicrochip,
        helperText: 'Identification number for your pet',
        suffixIcon: AppFormInfoButton(
          message:
              'Enter the identification number relevant to your pet:\n\n'
              '\u2022 Dogs & Cats: microchip number (usually 15 digits), often required by law\n'
              '\u2022 Horses & Ponies: passport or microchip number\n'
              '\u2022 Ferrets & Rabbits: microchip number if implanted\n'
              '\u2022 Birds: leg ring or band number\n'
              '\u2022 Fish: tank or habitat label\n'
              '\u2022 Other pets: any ID tag or registration number\n\n'
              'This is essential if your pet is lost or needs emergency vet care. '
              'The number is usually found on adoption papers, vet records, or the registration database.',
        ),
      ),
      onChanged: onChanged,
    );
  }
}
