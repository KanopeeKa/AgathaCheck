import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../data/datasources/care_context_remote_datasource.dart';
import '../../domain/entities/planned_absence_pet_carer.dart';
import '../providers/care_context_providers.dart';

class AwayPlanPetNotesSection extends ConsumerStatefulWidget {
  const AwayPlanPetNotesSection({
    super.key,
    required this.absenceId,
    required this.petId,
    required this.petName,
    required this.currentCarer,
    required this.canEdit,
  });

  final String absenceId;
  final String petId;
  final String petName;
  final PlannedAbsencePetCarer currentCarer;
  final bool canEdit;

  @override
  ConsumerState<AwayPlanPetNotesSection> createState() =>
      _AwayPlanPetNotesSectionState();
}

class _AwayPlanPetNotesSectionState
    extends ConsumerState<AwayPlanPetNotesSection> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentCarer.petNote ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant AwayPlanPetNotesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextNote = widget.currentCarer.petNote ?? '';
    if (nextNote != _controller.text && !_saving) {
      _controller.text = nextNote;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!widget.canEdit || _saving) return;
    final l = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      final note = _controller.text.trim();
      await ref
          .read(careContextRepositoryProvider)
          .patchPerPetAwayPlan(
            absenceId: widget.absenceId,
            petId: widget.petId,
            body: {'pet_note': note.isEmpty ? null : note},
          );
      if (!mounted) return;
      ref.invalidate(plannedAbsenceDetailProvider(widget.absenceId));
      ref.invalidate(awayPlanReadinessProvider(widget.absenceId));
      ref.invalidate(
        perPetAwayPlanStatusProvider((
          absenceId: widget.absenceId,
          petId: widget.petId,
        )),
      );
    } on CareContextApiException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.careContextPetNotesSaveFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.careContextPetNotesSectionTitle(widget.petName),
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Semantics(
          identifier: 'away_plan_pet_notes_${widget.petId}',
          container: true,
          child: TextField(
            key: Key('away_plan_pet_notes_${widget.petId}'),
            controller: _controller,
            readOnly: !widget.canEdit || _saving,
            minLines: 2,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: l.awayPlanningCarerEditPetNoteLabel(widget.petName),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: widget.canEdit ? (_) => _save() : null,
          ),
        ),
        if (widget.canEdit) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Semantics(
              identifier: 'away_plan_pet_notes_save_${widget.petId}',
              button: true,
              label: l.save,
              child: FilledButton(
                key: Key('away_plan_pet_notes_save_${widget.petId}'),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l.save),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
