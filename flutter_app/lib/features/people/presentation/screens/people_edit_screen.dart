import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/models/people_contact_model.dart';
import '../providers/people_providers.dart';

class PeopleEditScreen extends ConsumerStatefulWidget {
  const PeopleEditScreen({super.key, required this.personId});

  final String personId;

  @override
  ConsumerState<PeopleEditScreen> createState() => _PeopleEditScreenState();
}

class _PeopleEditScreenState extends ConsumerState<PeopleEditScreen> {
  final _noteController = TextEditingController();
  bool _saving = false;
  bool _loaded = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _loadNote(String note) {
    if (_loaded) return;
    _noteController.text = note;
    _loaded = true;
  }

  Future<void> _save(PeopleContactModel model) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(peopleContactsProvider.notifier)
          .updateContact(
            model.copyWith(privateNote: _noteController.text.trim()),
          );
      if (mounted) context.pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmRemove(String name) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.peopleRemoveContactTitle),
        content: Text(l.peopleRemoveContactBody(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.peopleRemoveContactConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref
        .read(peopleContactsProvider.notifier)
        .deleteContact(widget.personId);
    if (mounted) {
      context.go('/pc/people');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final contact = ref.watch(peopleContactByIdProvider(widget.personId));
    if (contact == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.peopleEditPerson)),
        body: Center(child: Text(l.peopleDetailNotFound)),
      );
    }

    final model = PeopleContactModel(
      id: contact.id,
      kind: contact.kind,
      name: contact.name,
      roles: contact.roles,
      phone: contact.phone,
      email: contact.email,
      address: contact.address,
      website: contact.website,
      privateNote: contact.privateNote,
      inactiveAt: contact.inactiveAt,
      legacyVetId: contact.legacyVetId,
    );
    _loadNote(contact.privateNote);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.peopleEditPerson),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => _save(model),
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l.save),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: l.peopleNameLabel,
              prefixIcon: const Icon(Icons.person_outlined),
            ),
            controller: TextEditingController(text: contact.name),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(labelText: l.peoplePrivateNoteLabel),
            minLines: 2,
            maxLines: 5,
          ),
          const SizedBox(height: 32),
          Text(
            l.peopleDangerZoneTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('people_edit_remove_contact'),
            onPressed: () => _confirmRemove(contact.name),
            icon: const Icon(Icons.person_remove_outlined),
            label: Text(l.peopleRemoveContactConfirm),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
