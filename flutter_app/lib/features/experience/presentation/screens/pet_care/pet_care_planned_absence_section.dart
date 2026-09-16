import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_care/context/presentation/widgets/planned_absence_entry_tile.dart';
import '../../widgets/pet_care_dashboard_section_header.dart';

/// Guardian dashboard away-planning preview between care actions and vets.
class PetCarePlannedAbsenceSection extends StatelessWidget {
  const PetCarePlannedAbsenceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Semantics(
      container: true,
      label: l.awayPlanningEyebrow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PetCareDashboardSectionHeader(title: l.awayPlanningEyebrow),
          const SizedBox(height: 10),
          const PlannedAbsenceEntryTile(),
          PetCareDashboardSectionLink(
            linkKey: const Key('pet_care_dashboard_all_absences'),
            label: l.allAbsences,
            onPressed: () => context.push('/pc/away'),
          ),
        ],
      ),
    );
  }
}
