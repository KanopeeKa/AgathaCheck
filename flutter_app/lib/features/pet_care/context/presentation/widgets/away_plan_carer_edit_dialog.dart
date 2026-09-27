import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../people/domain/entities/people_contact.dart';
import '../../../../people/presentation/providers/people_providers.dart';
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
  static const _clearContactId = '__clear__';

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
    if (_selectedContactId == _clearContactId) return true;
    return _selectedContactId != null && _selectedContactId!.isNotEmpty;
  }

  String? get _normalizedPetNote =>
      _petNoteController.text.trim().isEmpty ? null : _petNoteController.text;

  Map<String, dynamic> _payload() {
    if (_selectedContactId == _clearContactId) {
      return {
        'pet_id': widget.petId,
        'contact_id': null,
        'pet_note': _normalizedPetNote,
      };
    }
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
        ref.invalidate(peopleContactsProvider);
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

  List<PeopleContact> _selectableContacts(List<PeopleContact> all) {
    final active = all.where((c) => c.inactiveAt == null).toList();
    final currentId = widget.currentCarer.contactId;
    if (currentId != null &&
        currentId.isNotEmpty &&
        active.every((c) => c.id != currentId)) {
      final legacy = all.where((c) => c.id == currentId);
      if (legacy.isNotEmpty) {
        return [legacy.first, ...active];
      }
    }
    return active;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final contactsAsync = ref.watch(peopleContactsProvider);

    return AlertDialog(
      title: Text(l.awayPlanningCarerEditTitle(widget.petName)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            contactsAsync.when(
              loading: () => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l.awayPlanningCarerEditCandidatesLoading,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              error: (_, __) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l.awayPlanningCarerEditCandidatesFailed,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
              data: (contacts) {
                final selectable = _selectableContacts(contacts);
                if (selectable.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      l.awayPlanningCarerEditContactsEmpty,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                }
                return RadioGroup<String?>(
                  groupValue: _selectedContactId,
                  onChanged: (value) =>
                      setState(() => _selectedContactId = value),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final contact in selectable)
                        RadioListTile<String?>(
                          key: Key('away_plan_carer_contact_${contact.id}'),
                          value: contact.id,
                          title: Text(contact.name),
                        ),
                      RadioListTile<String?>(
                        key: const Key('away_plan_carer_contact_clear'),
                        value: _clearContactId,
                        title: Text(l.awayPlanningCarerEditClear),
                      ),
                    ],
                  ),
                );
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
