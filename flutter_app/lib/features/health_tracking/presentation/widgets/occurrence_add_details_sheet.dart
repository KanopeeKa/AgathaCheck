import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/health_entry.dart';
import '../controllers/health_entry_form_constants.dart';
import '../controllers/care_schedule_controller.dart';
import '../utils/health_document_picker.dart';
import 'care_provider_field.dart';
import 'care_schedule_command_feedback.dart';

/// Optional note and occurrence-scoped documents after mark done.
Future<void> showOccurrenceAddDetailsSheet(
  BuildContext context,
  WidgetRef ref, {
  required HealthEntry entry,
  required String occurrenceId,
  String initialNotes = '',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => OccurrenceAddDetailsSheet(
      entry: entry,
      occurrenceId: occurrenceId,
      initialNotes: initialNotes,
    ),
  );
}

class OccurrenceAddDetailsSheet extends ConsumerStatefulWidget {
  const OccurrenceAddDetailsSheet({
    super.key,
    required this.entry,
    required this.occurrenceId,
    this.initialNotes = '',
  });

  final HealthEntry entry;
  final String occurrenceId;
  final String initialNotes;

  @override
  ConsumerState<OccurrenceAddDetailsSheet> createState() =>
      _OccurrenceAddDetailsSheetState();
}

class _OccurrenceAddDetailsSheetState
    extends ConsumerState<OccurrenceAddDetailsSheet> {
  late final TextEditingController _notesController;
  final List<_PendingDoc> _pendingDocs = [];
  bool _saving = false;
  String? _providerContactId;
  String? _providerTypedName;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.initialNotes);
    _providerContactId = widget.entry.providerContactId;
    _providerTypedName = widget.entry.providerTypedName;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    if (_pendingDocs.length >= healthEntryMaxPhotos) return;
    final picked = await pickSingleHealthDocument();
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    if (bytes.isEmpty) return;
    final ext = picked.name.split('.').last.toLowerCase();
    if (!healthDocumentAllowedExtensions.contains(ext)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.unsupportedDocumentFormat,
          ),
        ),
      );
      return;
    }
    if (bytes.length > healthDocumentMaxBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.documentTooLarge)),
      );
      return;
    }
    setState(() {
      _pendingDocs.add(_PendingDoc(name: picked.name, bytes: bytes));
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final l = AppLocalizations.of(context)!;
    try {
      final notes = _notesController.text.trim();
      final outcome = await ref
          .read(careScheduleControllerProvider)
          .updateOccurrenceDetails(
            widget.entry.id,
            widget.occurrenceId,
            notes: notes,
            providerContactId: _providerContactId,
            providerTypedName: _providerTypedName,
            pendingDocuments: _pendingDocs
                .map((d) => (name: d.name, bytes: d.bytes))
                .toList(),
          );
      if (!mounted) return;
      Navigator.pop(context);
      showCareScheduleCommandSnackBar(
        context,
        outcome: outcome,
        successMessage: l.careDetailsSaved,
        failureMessage: l.careDetailsSaveFailed,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.careDetailsSaveFailed)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.careAddDetailsTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(labelText: l.notes),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          CareProviderField(
            contactId: _providerContactId,
            typedName: _providerTypedName,
            onChanged: ({contactId, typedName}) {
              setState(() {
                _providerContactId = contactId;
                _providerTypedName = typedName;
              });
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _saving ? null : _pickDocument,
            icon: const Icon(Icons.attach_file),
            label: Text(l.addPhoto),
          ),
          if (_pendingDocs.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._pendingDocs.map(
              (d) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  d.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l.save),
          ),
        ],
      ),
    );
  }
}

class _PendingDoc {
  const _PendingDoc({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}
