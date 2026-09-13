import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/domain/entities/care_family.dart';
import '../../../pet_profile/domain/services/care_family_write.dart';
import '../../../pet_profile/presentation/widgets/care_family_labels.dart';

/// Dropdown for explicit [care_family] on health entry writes (CP-0 / C2).
class CareFamilyPickerField extends StatelessWidget {
  const CareFamilyPickerField({
    super.key,
    required this.value,
    required this.onChanged,
    this.required = false,
    this.errorText,
    this.options = kRecurringCareFamilyPickerOptions,
  });

  final CareFamily? value;
  final ValueChanged<CareFamily> onChanged;
  final bool required;
  final String? errorText;
  final List<CareFamily> options;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.careFamilyFieldLabel,
      child: DropdownButtonFormField<CareFamily?>(
        key: const Key('care_family_picker'),
        value: value,
        decoration: InputDecoration(
          labelText: l10n.careFamilyFieldLabel,
          helperText: errorText == null ? l10n.careFamilyFieldHelper : null,
          errorText: errorText,
          border: const OutlineInputBorder(),
        ),
        items: [
          DropdownMenuItem<CareFamily?>(
            value: null,
            enabled: false,
            child: Text(
              l10n.careFamilySelectHint,
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
          ),
          ...options.map(
            (family) => DropdownMenuItem<CareFamily?>(
              value: family,
              child: Text(careFamilyLabel(l10n, family)),
            ),
          ),
        ],
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      ),
    );
  }
}
