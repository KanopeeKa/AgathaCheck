import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/models/people_contact_model.dart';
import '../providers/people_providers.dart';

class PeopleContactFormScreen extends ConsumerStatefulWidget {
  const PeopleContactFormScreen({super.key});

  @override
  ConsumerState<PeopleContactFormScreen> createState() =>
      _PeopleContactFormScreenState();
}

class _PeopleContactFormScreenState
    extends ConsumerState<PeopleContactFormScreen> {
  final _nameController = TextEditingController();
  String _kind = 'person';
  final Set<String> _roles = {'sitter'};
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(peopleContactsProvider.notifier)
          .addContact(
            PeopleContactModel(
              id: '',
              kind: _kind,
              name: name,
              roles: _roles.toList(),
            ),
          );
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.peopleAddPerson)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: l.peopleNameLabel),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _kind,
            decoration: InputDecoration(labelText: l.peopleKindLabel),
            items: [
              DropdownMenuItem(
                value: 'person',
                child: Text(l.peopleKindPerson),
              ),
              DropdownMenuItem(
                value: 'organisation',
                child: Text(l.peopleKindOrganisation),
              ),
            ],
            onChanged: (v) => setState(() => _kind = v ?? 'person'),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              _roleChip('sitter', l.peopleRoleSitter),
              _roleChip('vet', l.peopleRoleVet),
              _roleChip('groomer', l.peopleRoleGroomer),
            ],
          ),
          const SizedBox(height: 24),
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

  Widget _roleChip(String role, String label) {
    final selected = _roles.contains(role);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (v) {
        setState(() {
          if (v) {
            _roles.add(role);
          } else {
            _roles.remove(role);
          }
        });
      },
    );
  }
}
