import 'package:flutter/material.dart';
import '../../../../../core/utils/calendar_date.dart';
import '../../../../../l10n/app_localizations.dart';
import 'pet_form_info_tooltip.dart';

class PetFormNeuteredSection extends StatelessWidget {
  const PetFormNeuteredSection({
    super.key,
    required this.isNeutered,
    required this.neuteredDate,
    required this.onNeuteredChanged,
    required this.onPickNeuteredDate,
    required this.onClearNeuteredDate,
  });

  final bool? isNeutered;
  final DateTime? neuteredDate;
  final ValueChanged<bool?> onNeuteredChanged;
  final VoidCallback onPickNeuteredDate;
  final VoidCallback onClearNeuteredDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l.neuteredSpayedDate,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            PetFormInfoTooltip(
              message:
                  'Whether your pet has been surgically sterilised:\n\n'
                  '\u2022 Neutered: male animals (castration)\n'
                  '\u2022 Spayed: female animals (ovariectomy / ovariohysterectomy)\n\n'
                  'This applies to dogs, cats, rabbits, and other mammals. '
                  'Recording the date helps your vet track recovery and adjust any health recommendations.\n\n'
                  'If your pet is not yet neutered/spayed, selecting "No" will show a reminder on their profile.',
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            SizedBox(
              width: 120,
              child: RadioListTile<bool>(
                key: const Key('pet_neutered_yes'),
                title: const Text('Yes'),
                value: true,
                groupValue: isNeutered,
                dense: true,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => onNeuteredChanged(val),
              ),
            ),
            SizedBox(
              width: 120,
              child: RadioListTile<bool>(
                key: const Key('pet_neutered_no'),
                title: const Text('No'),
                value: false,
                groupValue: isNeutered,
                dense: true,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => onNeuteredChanged(val),
              ),
            ),
          ],
        ),
        if (isNeutered == true)
          InkWell(
            key: const Key('pet_neutered_date_field'),
            onTap: onPickNeuteredDate,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l.date,
                suffixIcon: neuteredDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        tooltip: 'Clear date',
                        onPressed: onClearNeuteredDate,
                      )
                    : null,
              ),
              child: Text(
                neuteredDate != null
                    ? formatCalendarDateDisplay(neuteredDate!)
                    : 'Select date (optional)',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: neuteredDate != null
                      ? null
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
