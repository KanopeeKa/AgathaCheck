import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../domain/entities/planned_absence.dart';
import '../../domain/entities/planned_absence_pet_carer.dart';
import '../away_plan_copy.dart';
import 'away_plan_carer_edit_dialog.dart';

class AwayPlanCarersSection extends ConsumerWidget {
  const AwayPlanCarersSection({
    super.key,
    required this.absence,
    required this.petNamesById,
  });

  final PlannedAbsence absence;
  final Map<String, String> petNamesById;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final carersByPetId = {
      for (final carer in absence.petCarers) carer.petId: carer,
    };
    final orderedPetIds = [...absence.petIds]..sort();
    final canEdit = !absence.isCancelled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.careContextAwayPlanWhoIsCaringTitle,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final petId in orderedPetIds) ...[
                  _CarerRow(
                    petName: petNamesById[petId] ?? '',
                    carerLabel: AwayPlanCopy.petCarerLabel(
                      l,
                      carersByPetId[petId] ??
                          PlannedAbsencePetCarer(petId: petId),
                    ),
                    canEdit: canEdit,
                    onEdit: () => _openEditDialog(context, petId),
                  ),
                  if (petId != orderedPetIds.last) const Divider(height: 24),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openEditDialog(BuildContext context, String petId) async {
    final carer = absence.petCarers.firstWhere(
      (row) => row.petId == petId,
      orElse: () => PlannedAbsencePetCarer(petId: petId),
    );
    await showDialog<bool>(
      context: context,
      builder: (_) => AwayPlanCarerEditDialog(
        absenceId: absence.id,
        petId: petId,
        petName: petNamesById[petId] ?? '',
        currentCarer: carer,
      ),
    );
  }
}

class _CarerRow extends StatelessWidget {
  const _CarerRow({
    required this.petName,
    required this.carerLabel,
    required this.canEdit,
    required this.onEdit,
  });

  final String petName;
  final String carerLabel;
  final bool canEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(petName, style: theme.textTheme.titleSmall)),
        Expanded(
          child: Text(
            carerLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        SizedBox(
          width: 48,
          height: 48,
          child: IconButton(
            key: const Key('away_plan_carer_edit'),
            tooltip: l.awayPlanningCarerEditSharedUser,
            icon: const Icon(Icons.edit_outlined),
            onPressed: canEdit ? onEdit : null,
          ),
        ),
      ],
    );
  }
}
