import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../domain/entities/planned_absence.dart';
import '../../domain/entities/planned_absence_pet_carer.dart';
import '../away_plan_copy.dart';
import '../controllers/away_plan_handover_controller.dart';
import 'away_plan_carer_edit_dialog.dart';

class AwayPlanPetCarerPanel extends ConsumerWidget {
  const AwayPlanPetCarerPanel({
    super.key,
    required this.absence,
    required this.petId,
    required this.petName,
    required this.petNamesById,
  });

  final PlannedAbsence absence;
  final String petId;
  final String petName;
  final Map<String, String> petNamesById;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final carer = absence.petCarers.firstWhere(
      (row) => row.petId == petId,
      orElse: () => PlannedAbsencePetCarer(petId: petId),
    );
    final canEdit = !absence.isCancelled;
    final carerLabel = AwayPlanCopy.petCarerLabel(l, carer);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.careContextAwayPlanWhoIsCaringTitle,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    identifier: 'away_plan_pet_carer_label_$petId',
                    label: carerLabel,
                    child: Text(
                      carerLabel,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ),
                IconButton(
                  key: Key('away_plan_pet_carer_edit_$petId'),
                  tooltip: l.awayPlanningCarerEditButtonLabel(petName),
                  onPressed: canEdit
                      ? () => showDialog<bool>(
                            context: context,
                            builder: (_) => AwayPlanCarerEditDialog(
                              absenceId: absence.id,
                              petId: petId,
                              petName: petName,
                              currentCarer: carer,
                            ),
                          )
                      : null,
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> downloadPetHandover(BuildContext context, WidgetRef ref) {
    return AwayPlanHandoverController(ref).downloadPetHandover(
      context: context,
      absence: absence,
      petId: petId,
      petNamesById: petNamesById,
    );
  }
}
