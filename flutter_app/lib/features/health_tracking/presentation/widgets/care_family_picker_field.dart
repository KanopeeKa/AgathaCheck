import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/domain/entities/care_family.dart';
import '../../../pet_profile/domain/services/care_family_write.dart';
import '../../../pet_profile/presentation/widgets/care_family_labels.dart';

/// Dropdown for explicit [care_family] on recurring health entry writes (CP-0).
class CareFamilyPickerField extends StatelessWidget {
  const CareFamilyPickerField({
    super.key,
    required this.value,
    required this.onChanged,
    this.options = kRecurringCareFamilyPickerOptions,
  });

  final CareFamily value;
  final ValueChanged<CareFamily> onChanged;
  final List<CareFamily> options;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DropdownButtonFormField<CareFamily>(
      key: ValueKey('care_family_picker_$value'),
      initialValue: value,
      decoration: InputDecoration(
        labelText: l10n.careFamilyFieldLabel,
        helperText: l10n.careFamilyFieldHelper,
        border: const OutlineInputBorder(),
      ),
      items: options
          .map(
            (family) => DropdownMenuItem(
              value: family,
              child: Text(careFamilyLabel(l10n, family)),
            ),
          )
          .toList(),
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }
}
