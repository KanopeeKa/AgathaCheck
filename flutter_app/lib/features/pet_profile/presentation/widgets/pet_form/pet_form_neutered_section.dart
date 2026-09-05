import 'package:flutter/material.dart';

import '../../../../../core/utils/calendar_date.dart';
import '../../../../../core/utils/constants.dart';
import '../../../../../l10n/app_localizations.dart';
import 'pet_form_info_tooltip.dart';
import 'pet_form_labeled_field.dart';

enum PetNeuterSelection { yes, no, unknown }

PetNeuterSelection? petNeuterSelectionFromState({
  required bool? isNeutered,
  required DateTime? neuteredDate,
}) {
  if (isNeutered == true || neuteredDate != null) return PetNeuterSelection.yes;
  if (isNeutered == false) return PetNeuterSelection.no;
  return PetNeuterSelection.unknown;
}

class PetFormNeuteredSection extends StatelessWidget {
  const PetFormNeuteredSection({
    super.key,
    this.species = '',
    required this.isNeutered,
    required this.neuteredDate,
    required this.onNeuteredChanged,
    required this.onPickNeuteredDate,
    required this.onClearNeuteredDate,
  });

  final String species;
  final bool? isNeutered;
  final DateTime? neuteredDate;
  final ValueChanged<bool?> onNeuteredChanged;
  final VoidCallback onPickNeuteredDate;
  final VoidCallback onClearNeuteredDate;

  bool get _notApplicable =>
      AppConstants.speciesWithoutNeutering.contains(species);

  void _onSelectionChanged(PetNeuterSelection selection) {
    switch (selection) {
      case PetNeuterSelection.yes:
        onNeuteredChanged(true);
      case PetNeuterSelection.no:
        onNeuteredChanged(false);
      case PetNeuterSelection.unknown:
        onNeuteredChanged(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    if (_notApplicable) {
      return PetFormLabeledField(
        label: l.neuteredSpayedDate,
        child: Container(
          key: const Key('pet_neuter_not_applicable'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            l.petNeuterNotApplicable,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final selection = petNeuterSelectionFromState(
      isNeutered: isNeutered,
      neuteredDate: neuteredDate,
    );

    return PetFormLabeledField(
      label: l.neuteredSpayedDate,
      subtitle: l.petNeuterSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: SegmentedButton<PetNeuterSelection>(
                  segments: [
                    ButtonSegment(
                      value: PetNeuterSelection.yes,
                      label: Text(l.petNeuterYes),
                    ),
                    ButtonSegment(
                      value: PetNeuterSelection.no,
                      label: Text(l.petNeuterNo),
                    ),
                    ButtonSegment(
                      value: PetNeuterSelection.unknown,
                      label: Text(l.petNeuterUnknown),
                    ),
                  ],
                  selected: {selection ?? PetNeuterSelection.unknown},
                  onSelectionChanged: (values) {
                    _onSelectionChanged(values.first);
                  },
                ),
              ),
              const SizedBox(width: 4),
              PetFormInfoTooltip(message: l.petNeuterTooltip),
            ],
          ),
          if (selection == PetNeuterSelection.yes) ...[
            const SizedBox(height: 12),
            InkWell(
              key: const Key('pet_neutered_date_field'),
              onTap: onPickNeuteredDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l.date,
                  suffixIcon: neuteredDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          tooltip: l.clearDate,
                          onPressed: onClearNeuteredDate,
                        )
                      : const Icon(Icons.calendar_today, size: 18),
                ),
                child: Text(
                  neuteredDate != null
                      ? formatCalendarDateMedium(neuteredDate!)
                      : l.petFormSelectDate,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: neuteredDate != null
                        ? null
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
