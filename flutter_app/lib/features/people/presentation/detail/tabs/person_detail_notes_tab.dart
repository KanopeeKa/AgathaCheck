import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../application/people_commands.dart';
import '../../../domain/entities/contact_detail.dart';

class PersonDetailNotesTab extends ConsumerStatefulWidget {
  const PersonDetailNotesTab({
    super.key,
    required this.contactId,
    required this.detail,
    required this.showHouseholdNote,
  });

  final String contactId;
  final ContactDetail detail;
  final bool showHouseholdNote;

  @override
  ConsumerState<PersonDetailNotesTab> createState() =>
      _PersonDetailNotesTabState();
}

class _PersonDetailNotesTabState extends ConsumerState<PersonDetailNotesTab> {
  late final TextEditingController _privateController;
  late final TextEditingController _householdController;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _privateController = TextEditingController(text: widget.detail.privateNote);
    _householdController = TextEditingController(
      text: widget.detail.householdNote ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant PersonDetailNotesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail.privateNote != widget.detail.privateNote) {
      _privateController.text = widget.detail.privateNote;
    }
    if (oldWidget.detail.householdNote != widget.detail.householdNote) {
      _householdController.text = widget.detail.householdNote ?? '';
    }
  }

  @override
  void dispose() {
    _privateController.dispose();
    _householdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l.peoplePrivateNoteLabel, style: theme.textTheme.titleSmall),
        Text(
          l.peoplePrivateNoteHelper,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('people_detail_private_note'),
          controller: _privateController,
          minLines: 3,
          maxLines: 6,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: l.peoplePrivateNoteLabel,
          ),
        ),
        if (widget.showHouseholdNote) ...[
          const SizedBox(height: 20),
          Text(
            l.peopleDetailHouseholdNoteLabel,
            style: theme.textTheme.titleSmall,
          ),
          Text(
            l.peopleDetailHouseholdNoteHelper,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('people_detail_household_note'),
            controller: _householdController,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: l.peopleDetailHouseholdNoteLabel,
            ),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('people_detail_save_notes'),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l.peopleDetailSaveNotes),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final l = AppLocalizations.of(context)!;
    try {
      await ref
          .read(peopleCommandsProvider)
          .saveContactNotes(
            widget.contactId,
            privateNote: _privateController.text,
            householdNote: widget.showHouseholdNote
                ? _householdController.text
                : null,
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.peopleDetailNotesSaved)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
