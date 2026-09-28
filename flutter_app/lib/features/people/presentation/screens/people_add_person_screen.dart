import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/models/people_contact_model.dart';
import '../../domain/entities/people_contact.dart';
import '../providers/people_providers.dart';

/// Unified add-person flow: identity → dedupe hint → relationship → save.
class PeopleAddPersonScreen extends ConsumerStatefulWidget {
  const PeopleAddPersonScreen({super.key});

  @override
  ConsumerState<PeopleAddPersonScreen> createState() =>
      _PeopleAddPersonScreenState();
}

class _PeopleAddPersonScreenState extends ConsumerState<PeopleAddPersonScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  int _step = 0;
  String _kind = 'person';
  final Set<String> _roles = {'sitter'};
  bool _saving = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  List<PeopleContact> _dedupeMatches(List<PeopleContact> contacts) {
    final name = _nameController.text.trim().toLowerCase();
    if (name.length < 2) return const [];
    return contacts
        .where((c) => c.name.toLowerCase().contains(name))
        .take(3)
        .toList();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(peopleContactsProvider.notifier).addContact(
            PeopleContactModel(
              id: '',
              kind: _kind,
              name: name,
              roles: _roles.toList(),
            ),
          );
      if (!mounted) return;
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

  void _next() {
    if (_step < 2) {
      setState(() => _step++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final contactsAsync = ref.watch(peopleContactsProvider);
    final matches = contactsAsync.valueOrNull != null
        ? _dedupeMatches(contactsAsync.value!)
        : const <PeopleContact>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(l.peopleAddPerson),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: (_step + 1) / 3),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _IdentityStep(
            nameController: _nameController,
            kind: _kind,
            onKindChanged: (k) => setState(() => _kind = k),
          ),
          _DedupeStep(matches: matches),
          _RelationshipStep(
            roles: _roles,
            onRoleToggle: (role, selected) {
              setState(() {
                if (selected) {
                  _roles.add(role);
                } else {
                  _roles.remove(role);
                }
              });
            },
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _saving ? null : _next,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_step < 2 ? l.continueButton : l.peopleAddPersonSave),
          ),
        ),
      ),
    );
  }
}

class _IdentityStep extends StatelessWidget {
  const _IdentityStep({
    required this.nameController,
    required this.kind,
    required this.onKindChanged,
  });

  final TextEditingController nameController;
  final String kind;
  final ValueChanged<String> onKindChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l.peopleAddStepIdentity, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: l.peopleNameLabel),
          autofocus: true,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: kind,
          decoration: InputDecoration(labelText: l.peopleKindLabel),
          items: [
            DropdownMenuItem(value: 'person', child: Text(l.peopleKindPerson)),
            DropdownMenuItem(
              value: 'organisation',
              child: Text(l.peopleKindOrganisation),
            ),
          ],
          onChanged: (v) => onKindChanged(v ?? 'person'),
        ),
      ],
    );
  }
}

class _DedupeStep extends StatelessWidget {
  const _DedupeStep({required this.matches});

  final List<PeopleContact> matches;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l.peopleAddDedupeTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (matches.isEmpty)
          Text(l.peopleAddDedupeEmpty)
        else
          for (final m in matches)
            ListTile(
              leading: const Icon(Icons.person_search_outlined),
              title: Text(m.name),
              subtitle: Text(m.roles.join(' · ')),
            ),
        const SizedBox(height: 8),
        Text(
          l.peopleAddDedupeHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _RelationshipStep extends StatelessWidget {
  const _RelationshipStep({
    required this.roles,
    required this.onRoleToggle,
  });

  final Set<String> roles;
  final void Function(String role, bool selected) onRoleToggle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    const roleKeys = ['sitter', 'walker', 'vet', 'groomer'];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l.peopleAddStepRelationship,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        for (final role in roleKeys)
          CheckboxListTile(
            value: roles.contains(role),
            onChanged: (v) => onRoleToggle(role, v == true),
            title: Text(role),
          ),
      ],
    );
  }
}
