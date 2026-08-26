import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';

class PetGenderSection extends StatelessWidget {
  final String? selectedGender;
  final ValueChanged<String?> onChanged;

  const PetGenderSection({
    super.key,
    required this.selectedGender,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return DropdownButtonFormField<String?>(
      key: const Key('pet_gender_field'),
      initialValue: selectedGender,
      decoration: InputDecoration(
        labelText: l.gender,
        helperText: 'Useful for health and behaviour tracking',
        suffixIcon: selectedGender != null
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                tooltip: 'Clear gender',
                onPressed: () => onChanged(null),
              )
            : const Icon(Icons.info_outline),
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Not specified'),
        ),
        DropdownMenuItem(value: 'Male', child: Text(l.male)),
        DropdownMenuItem(value: 'Female', child: Text(l.female)),
      ],
      onChanged: onChanged,
    );
  }
}
