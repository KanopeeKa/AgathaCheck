import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import 'pet_form_info_tooltip.dart';

class PetFormInsuranceSection extends StatelessWidget {
  const PetFormInsuranceSection({
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
      key: const Key('pet_insurance_field'),
      controller: textController,
      decoration: InputDecoration(
        labelText: l.insuranceDetails,
        alignLabelWithHint: true,
        helperText: 'Policy info for emergencies or vet visits',
        suffixIcon: PetFormInfoTooltip(
          message:
              'Include details someone else would need to use your pet\'s insurance:\n\n'
              '\u2022 Insurance company name\n'
              '\u2022 Policy or contract number\n'
              '\u2022 Policyholder name (if different from you)\n'
              '\u2022 Coverage type (accident only, illness, wellness)\n'
              '\u2022 Excess/deductible amount\n'
              '\u2022 Emergency helpline number\n\n'
              'This is especially useful if a pet-sitter or family member needs to take your pet to the vet and claim on your behalf.',
        ),
      ),
      maxLines: 4,
      maxLength: 500,
      onChanged: onChanged,
    );
  }
}
