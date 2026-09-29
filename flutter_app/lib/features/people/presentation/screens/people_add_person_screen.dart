import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/models/people_contact_model.dart';
import '../../domain/entities/people_contact.dart';
import '../providers/people_providers.dart';
import '../utils/people_contact_dedupe.dart';
import '../utils/people_contact_kind_inference.dart';
import '../utils/people_contact_role_labels.dart';

/// Single-screen add contact: name, roles, optional coordinates, dedupe suggestions.
class PeopleAddPersonScreen extends ConsumerStatefulWidget {
  const PeopleAddPersonScreen({
    super.key,
    this.initialRoles = const {},
    this.popResultOnSave = false,
  });

  final Set<String> initialRoles;
  final bool popResultOnSave;

  @override
  ConsumerState<PeopleAddPersonScreen> createState() =>
      _PeopleAddPersonScreenState();
}

class _PeopleAddPersonScreenState extends ConsumerState<PeopleAddPersonScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  final Set<String> _roles = {};
  bool _contactExpanded = false;
  String? _forcedKind;
  String? _worksAtContactId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _roles.addAll(
      widget.initialRoles.isEmpty ? {'sitter'} : widget.initialRoles,
    );
    if (_roles.contains('vet')) {
      _contactExpanded = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _resolvedKind() {
    if (_forcedKind != null) return _forcedKind!;
    return inferPeopleContactKind(name: _nameController.text, roles: _roles);
  }

  List<PeopleContact> _dedupeMatches(List<PeopleContact> contacts) {
    return findDuplicateContacts(
      directory: contacts,
      name: _nameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _roles.isEmpty) return;
    setState(() => _saving = true);
    try {
      final created = await ref
          .read(peopleContactsProvider.notifier)
          .addContact(
            PeopleContactModel(
              id: '',
              kind: _resolvedKind(),
              name: name,
              roles: _roles.toList(),
              phone: _nullable(_phoneController.text),
              email: _nullable(_emailController.text),
              address: _nullable(_addressController.text),
              privateNote: _noteController.text.trim(),
              worksAtContactId: _worksAtContactId,
            ),
          );
      if (!mounted) return;
      if (widget.popResultOnSave) {
        context.pop(created);
        return;
      }
      final l = AppLocalizations.of(context)!;
      final offerShare = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.peopleAddAppAccessTitle),
          content: Text(l.peopleAddAppAccessBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.peopleAddAppAccessSkip),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.peopleAddAppAccessContinue),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (offerShare == true) {
        context.go('/pc/invite');
      } else {
        context.pop(true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _nullable(String value) {
    final t = value.trim();
    return t.isEmpty ? null : t;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final contactsAsync = ref.watch(peopleContactsProvider);
    final contacts = contactsAsync.valueOrNull ?? const <PeopleContact>[];
    final matches = _dedupeMatches(contacts);
    final organisations = contacts
        .where((c) => c.kind == 'organisation' && c.inactiveAt == null)
        .toList();
    final inferredKind = _resolvedKind();

    return Scaffold(
      appBar: AppBar(title: Text(l.peopleAddPerson)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: l.peopleNameLabel),
            autofocus: true,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Text(
            inferredKind == 'organisation'
                ? l.peopleKindInferredOrganisation
                : l.peopleKindInferredPerson,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          TextButton(
            onPressed: () {
              final inferred = inferPeopleContactKind(
                name: _nameController.text,
                roles: _roles,
              );
              setState(() {
                _forcedKind = inferred == 'person' ? 'organisation' : 'person';
              });
            },
            child: Text(l.peopleKindChange),
          ),
          if (matches.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              l.peopleAddDedupeTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            for (final m in matches)
              ListTile(
                leading: const Icon(Icons.person_search_outlined),
                title: Text(m.name),
                subtitle: Text(peopleContactRolesLine(l, m.roles)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/pc/people/${m.id}'),
              ),
          ],
          const SizedBox(height: 16),
          Text(
            l.peopleAddStepRelationship,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final role in const ['sitter', 'walker', 'vet', 'groomer'])
                FilterChip(
                  label: Text(peopleContactRoleLabel(l, role)),
                  selected: _roles.contains(role),
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _roles.add(role);
                      } else {
                        _roles.remove(role);
                      }
                    });
                  },
                ),
            ],
          ),
          if (_roles.contains('vet') && organisations.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _worksAtContactId,
              decoration: InputDecoration(labelText: l.peopleWorksAtLabel),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l.peopleWorksAtNone),
                ),
                for (final org in organisations)
                  DropdownMenuItem(value: org.id, child: Text(org.name)),
              ],
              onChanged: (v) => setState(() => _worksAtContactId = v),
            ),
          ],
          const SizedBox(height: 8),
          ExpansionTile(
            title: Text(l.peopleAddContactDetailsExpand),
            initiallyExpanded: _contactExpanded,
            onExpansionChanged: (v) => setState(() => _contactExpanded = v),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    TextField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: l.peoplePhoneLabel,
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: l.peopleEmailLabel,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: l.peopleAddressLabel,
                      ),
                      minLines: 2,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: l.peoplePrivateNoteLabel,
                        helperText: l.peoplePrivateNoteHelper,
                      ),
                      minLines: 2,
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _saving || _roles.isEmpty ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l.peopleAddPersonSave),
          ),
        ),
      ),
    );
  }
}
