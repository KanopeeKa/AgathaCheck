import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/router/shell_return_navigation.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../health_tracking/presentation/widgets/care_event_row_pet_avatar.dart';
import '../../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../domain/entities/planned_absence.dart';
import '../../domain/entities/planned_absence_pet_carer.dart';
import '../away_plan_copy.dart';
import '../controllers/away_plan_handover_controller.dart';
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
                    petId: petId,
                    petName: petNamesById[petId] ?? '',
                    carerLabel: AwayPlanCopy.petCarerLabel(
                      l,
                      carersByPetId[petId] ??
                          PlannedAbsencePetCarer(petId: petId),
                    ),
                    canEdit: canEdit,
                    onEdit: () => _openEditDialog(context, petId),
                    onDownload: () => _downloadPetHandover(context, ref, petId),
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

  Future<void> _downloadPetHandover(
    BuildContext context,
    WidgetRef ref,
    String petId,
  ) {
    return AwayPlanHandoverController(ref).downloadPetHandover(
      context: context,
      absence: absence,
      petId: petId,
      petNamesById: petNamesById,
    );
  }
}

class _CarerRow extends ConsumerWidget {
  const _CarerRow({
    required this.petId,
    required this.petName,
    required this.carerLabel,
    required this.canEdit,
    required this.onEdit,
    required this.onDownload,
  });

  final String petId;
  final String petName;
  final String carerLabel;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDownload;

  static const _kMinTouchTarget = 48.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final pet = ref.watch(petByIdProvider(petId)).valueOrNull;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Semantics(
            identifier: 'away_plan_carer_pet_header_$petId',
            button: true,
            label: l.petDetailsFor(petName),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => openPetDetail(context, petId),
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: _kMinTouchTarget,
                  ),
                  child: Row(
                    children: [
                      CareEventRowPetAvatar(pet: pet, petName: petName),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(petName, style: theme.textTheme.titleSmall),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Semantics(
              identifier: 'away_plan_carer_label_$petId',
              label: carerLabel,
              child: Text(
                carerLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 48,
          height: 48,
          child: IconButton(
            key: Key('away_plan_carer_edit_$petId'),
            tooltip: l.awayPlanningCarerEditButtonLabel(petName),
            icon: const Icon(Icons.edit_outlined),
            onPressed: canEdit ? onEdit : null,
          ),
        ),
        SizedBox(
          width: 48,
          height: 48,
          child: IconButton(
            key: Key('away_plan_download_pet_$petId'),
            tooltip: l.awayPlanningDownloadPetPlan(petName),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: canEdit ? onDownload : null,
          ),
        ),
      ],
    );
  }
}
