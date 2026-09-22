import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../care_taxonomy/domain/care_planning_mode.dart';

/// Segmented control for planned vs record (unplanned) care entry modes.
class CarePlanningToggle extends StatelessWidget {
  const CarePlanningToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final CarePlanningMode value;
  final ValueChanged<CarePlanningMode> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      label: l10n.carePlanningToggleLabel,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: l10n.carePlanningToggleLabel,
          helperText: l10n.carePlanningFieldHelper,
          border: const OutlineInputBorder(),
        ),
        child: SegmentedButton<CarePlanningMode>(
          key: const Key('care_planning_toggle'),
          segments: [
            ButtonSegment(
              value: CarePlanningMode.planned,
              label: Text(l10n.carePlanningPlanned),
            ),
            ButtonSegment(
              value: CarePlanningMode.unplanned,
              label: Text(l10n.carePlanningUnplanned),
            ),
          ],
          selected: {value},
          onSelectionChanged: enabled
              ? (selection) => onChanged(selection.first)
              : null,
        ),
      ),
    );
  }
}
