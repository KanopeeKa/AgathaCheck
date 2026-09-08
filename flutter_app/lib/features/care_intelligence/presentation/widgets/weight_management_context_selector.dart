import 'package:flutter/material.dart';

import '../../domain/weight_provenance.dart';

/// D3 — progressive weight management context capture (pet profile integration point).
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
    return DropdownButtonFormField<ManagementContext>(
      value: value,
      decoration: const InputDecoration(
        labelText: 'Weight management',
        helperText: 'Is this weight change already being managed?',
      ),
      items: ManagementContext.values
          .map(
            (ctx) => DropdownMenuItem(
              value: ctx,
              child: Text(_label(ctx)),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  String _label(ManagementContext ctx) => switch (ctx) {
        ManagementContext.none => 'Not sure / not managed',
        ManagementContext.vetManaged => 'Yes, with my vet',
        ManagementContext.carePlan => 'Yes, as part of a care plan',
        ManagementContext.treatmentRelated => 'Related to treatment',
      };
}
