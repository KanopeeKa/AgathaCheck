import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/weight_provenance.dart';

/// Weight management context capture (pet profile edit form integration point).
class WeightManagementContextSelector extends StatelessWidget {
  const WeightManagementContextSelector({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final ManagementContext value;
  final ValueChanged<ManagementContext> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return DropdownButtonFormField<ManagementContext>(
      value: value,
      decoration: InputDecoration(
        labelText: l.weightManagementContextLabel,
        helperText: l.weightManagementContextHelper,
      ),
      items: ManagementContext.values
          .map(
            (ctx) => DropdownMenuItem(value: ctx, child: Text(_label(ctx, l))),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  String _label(ManagementContext ctx, AppLocalizations l) => switch (ctx) {
    ManagementContext.none => l.weightManagementContextNone,
    ManagementContext.vetManaged => l.weightManagementContextVetManaged,
    ManagementContext.carePlan => l.weightManagementContextCarePlan,
    ManagementContext.treatmentRelated =>
      l.weightManagementContextTreatmentRelated,
  };
}
