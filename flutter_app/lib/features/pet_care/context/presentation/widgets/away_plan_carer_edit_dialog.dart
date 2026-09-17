import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../data/datasources/care_context_remote_datasource.dart';
import '../../domain/entities/carer_candidate.dart';
import '../../domain/entities/planned_absence_pet_carer.dart';
import '../providers/care_context_providers.dart';

/// Per-pet carer editor shown from the away plan "Who's caring" section.
///
/// Fetches carer candidates for the pet and lets the owner assign a shared
/// user, add a note-only carer, or clear the assignment. Saves only the
/// edited pet's `pet_carers` entry via the existing PATCH endpoint.
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

enum _CarerMode { sharedUser, noteOnly, clear }

class _AwayPlanCarerEditDialogState
    extends ConsumerState<AwayPlanCarerEditDialog> {
  late _CarerMode _mode;
  String? _selectedUserId;
  late final TextEditingController _nameController;
  late final TextEditingController _noteController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.currentCarer.carerKind == 'note_only'
          ? widget.currentCarer.carerName ?? ''
          : '',
    );
    _noteController = TextEditingController(
      text: widget.currentCarer.carerKind == 'note_only'
          ? widget.currentCarer.carerNote ?? ''
          : '',
    );
    _selectedUserId = widget.currentCarer.carerKind == 'shared_user'
        ? widget.currentCarer.carerUserId
        : null;
    _mode = switch (widget.currentCarer.carerKind) {
      'shared_user' => _CarerMode.sharedUser,
      'note_only' => _CarerMode.noteOnly,
      _ => _CarerMode.sharedUser,
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _canSave {
    switch (_mode) {
      case _CarerMode.sharedUser:
        return _selectedUserId != null && _selectedUserId!.isNotEmpty;
      case _CarerMode.noteOnly:
        return _nameController.text.trim().isNotEmpty;
      case _CarerMode.clear:
        return true;
    }
  }

  Map<String, dynamic> _payloadForMode() {
    switch (_mode) {
      case _CarerMode.sharedUser:
        return {
          'pet_id': widget.petId,
          'carer_kind': 'shared_user',
          'carer_user_id': _selectedUserId,
        };
      case _CarerMode.noteOnly:
        return {
          'pet_id': widget.petId,
          'carer_kind': 'note_only',
          'carer_name': _nameController.text.trim(),
          if (_noteController.text.trim().isNotEmpty)
            'carer_note': _noteController.text.trim(),
        };
      case _CarerMode.clear:
        return {'pet_id': widget.petId, 'carer_kind': null};
    }
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      await ref
          .read(careContextRepositoryProvider)
          .updatePetCarers(
            absenceId: widget.absenceId,
            petCarers: [_payloadForMode()],
          );
      ref.invalidate(plannedAbsenceDetailProvider(widget.absenceId));
      ref.invalidate(awayPlanReadinessProvider(widget.absenceId));
      if (mounted) Navigator.of(context).pop(true);
    } on CareContextApiException catch (err) {
      if (err.statusCode == 403) {
        ref.invalidate(carerCandidatesProvider(widget.petId));
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
    final candidatesAsync = ref.watch(carerCandidatesProvider(widget.petId));
    final hasCurrentSharedUser =
        widget.currentCarer.carerKind == 'shared_user' &&
        widget.currentCarer.carerUserId != null &&
        widget.currentCarer.carerUserId!.isNotEmpty;

    return AlertDialog(
      title: Text(l.awayPlanningCarerEditTitle(widget.petName)),
      content: SingleChildScrollView(
        child: RadioGroup<_CarerMode>(
          groupValue: _mode,
          onChanged: (value) {
            if (value != null) setState(() => _mode = value);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RadioListTile<_CarerMode>(
                key: const Key('away_plan_carer_mode_shared_user'),
                value: _CarerMode.sharedUser,
                title: Text(l.awayPlanningCarerEditSharedUser),
              ),
              if (_mode == _CarerMode.sharedUser)
                candidatesAsync.when(
                  loading: () => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      l.awayPlanningCarerEditCandidatesLoading,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  error: (_, __) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      l.awayPlanningCarerEditCandidatesFailed,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                  data: (candidates) => _CandidateList(
                    candidates: candidates,
                    selectedUserId: _selectedUserId,
                    hasCurrentSharedUser: hasCurrentSharedUser,
                    currentUserId: widget.currentCarer.carerUserId,
                    onSelected: (userId) =>
                        setState(() => _selectedUserId = userId),
                  ),
                ),
              RadioListTile<_CarerMode>(
                key: const Key('away_plan_carer_mode_note_only'),
                value: _CarerMode.noteOnly,
                title: Text(l.awayPlanningCarerEditNoteOnly),
              ),
              if (_mode == _CarerMode.noteOnly) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    key: const Key('away_plan_carer_note_only_name'),
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l.awayPlanningCarerEditNameLabel,
                    ),
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    key: const Key('away_plan_carer_note_only_note'),
                    controller: _noteController,
                    decoration: InputDecoration(
                      labelText: l.awayPlanningCarerEditNoteLabel,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                  ),
                ),
              ],
              RadioListTile<_CarerMode>(
                key: const Key('away_plan_carer_mode_clear'),
                value: _CarerMode.clear,
                title: Text(l.awayPlanningCarerEditClear),
              ),
            ],
          ),
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

class _CandidateList extends StatelessWidget {
  const _CandidateList({
    required this.candidates,
    required this.selectedUserId,
    required this.hasCurrentSharedUser,
    required this.currentUserId,
    required this.onSelected,
  });

  final List<CarerCandidate> candidates;
  final String? selectedUserId;
  final bool hasCurrentSharedUser;
  final String? currentUserId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (candidates.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          l.awayPlanningCarerEditCandidatesEmpty,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    final list = [...candidates];
    if (hasCurrentSharedUser &&
        currentUserId != null &&
        list.every((c) => c.userId != currentUserId)) {
      list.insert(0, CarerCandidate(userId: currentUserId!, displayName: ''));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: RadioGroup<String>(
        groupValue: selectedUserId,
        onChanged: (value) {
          if (value != null) onSelected(value);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final candidate in list)
              RadioListTile<String>(
                key: Key('away_plan_carer_candidate_${candidate.userId}'),
                value: candidate.userId,
                title: Text(
                  candidate.displayName.isEmpty
                      ? l.awayPlanningCarerSharedUserFallback
                      : candidate.displayName,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
