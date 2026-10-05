import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../people/people.dart';
import '../../data/datasources/care_context_remote_datasource.dart';
import '../../domain/entities/planned_absence_pet_carer.dart';
import '../providers/care_context_providers.dart';

/// Per-pet carer editor — assigns a directory contact (People phase 2).
class AwayPlanCarerEditDialog extends ConsumerStatefulWidget {
  const AwayPlanCarerEditDialog({
    super.key,
    required this.absenceId,
    required this.petId,
    required this.petName,
    required this.currentCarer,
  });

  final String absenceId;
  final String petId;
  final String petName;
  final PlannedAbsencePetCarer currentCarer;

  @override
  ConsumerState<AwayPlanCarerEditDialog> createState() =>
      _AwayPlanCarerEditDialogState();
}

class _AwayPlanCarerEditDialogState
    extends ConsumerState<AwayPlanCarerEditDialog> {
  String? _selectedContactId;
  late final TextEditingController _petNoteController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedContactId = widget.currentCarer.contactId;
    _petNoteController = TextEditingController(
      text: widget.currentCarer.petNote ?? '',
    );
  }

  @override
  void dispose() {
    _petNoteController.dispose();
    super.dispose();
  }

  bool get _canSave {
    if (_selectedContactId != null && _selectedContactId!.isNotEmpty) {
      return true;
    }
    return widget.currentCarer.contactId != null;
  }

  String? get _normalizedPetNote =>
      _petNoteController.text.trim().isEmpty ? null : _petNoteController.text;

  Map<String, dynamic> _payload() {
    return {
      'pet_id': widget.petId,
      'contact_id': _selectedContactId,
      'pet_note': _normalizedPetNote,
    };
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      await ref
          .read(careContextRepositoryProvider)
          .updatePetCarers(
            absenceId: widget.absenceId,
            petCarers: [_payload()],
          );
      if (!mounted) return;
      ref.invalidate(plannedAbsenceDetailProvider(widget.absenceId));
      ref.invalidate(awayPlanReadinessProvider(widget.absenceId));
      Navigator.of(context).pop(true);
    } on CareContextApiException catch (err) {
      if (!mounted) return;
      if (err.statusCode == 403) {
        ref.invalidate(rosterProvider);
        _showFailure(l.awayPlanningCarerEditSaveFailedForbidden);
      } else {
        _showFailure(l.awayPlanningCarerEditSaveFailed);
      }
    } catch (_) {
      _showFailure(l.awayPlanningCarerEditSaveFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showFailure(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final selected = _selectedContactId == null
        ? null
        : ref.watch(personSummaryProvider(_selectedContactId!));

    return AlertDialog(
      title: Text(l.awayPlanningCarerEditTitle(widget.petName)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PeoplePickerField(
              purpose: 'away_plan_carer',
              query: PeopleQuery(
                groups: const {ContactGroup.carer},
                includeHouseholdMembers: true,
                allowNone: true,
                currentId: widget.currentCarer.contactId,
              ),
              value: selected,
              placeholder: l.awayPlanningCarerEditContactsEmpty,
              quickAddGroup: ContactGroup.carer,
              onChanged: (PeoplePickerResult? result) {
                switch (result) {
                  case PeoplePickerContactResult(:final contact):
                    setState(() => _selectedContactId = contact.id);
                  case PeoplePickerNoneResult():
                    setState(() => _selectedContactId = null);
                  case null:
                  case PeoplePickerTypedNameResult():
                    break;
                }
              },
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                key: const Key('away_plan_carer_pet_note'),
                controller: _petNoteController,
                decoration: InputDecoration(
                  labelText: l.awayPlanningCarerEditPetNoteLabel(
                    widget.petName,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                minLines: 2,
                maxLines: 4,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('away_plan_carer_edit_cancel'),
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('away_plan_carer_edit_save'),
          onPressed: (_saving || !_canSave) ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l.awayPlanningCarerEditSaveAction),
        ),
      ],
    );
  }
}
