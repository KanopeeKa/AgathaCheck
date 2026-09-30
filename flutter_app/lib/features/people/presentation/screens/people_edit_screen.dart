import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/form/app_form_discard_dialog.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/people_remote_datasource.dart';
import '../../data/models/people_contact_model.dart';
import '../../domain/entities/people_contact.dart';
import '../providers/people_providers.dart';

class PeopleEditScreen extends ConsumerStatefulWidget {
  const PeopleEditScreen({super.key, required this.personId});

  final String personId;

  @override
  ConsumerState<PeopleEditScreen> createState() => _PeopleEditScreenState();
}

class _PeopleEditScreenState extends ConsumerState<PeopleEditScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _websiteController = TextEditingController();
  final _noteController = TextEditingController();
  bool _saving = false;
  bool _loaded = false;
  PeopleContactModel? _original;
  String? _worksAtContactId;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _loadFromContact(PeopleContactModel model) {
    if (_loaded) return;
    _original = model;
    _nameController.text = model.name;
    _phoneController.text = model.phone ?? '';
    _emailController.text = model.email ?? '';
    _addressController.text = model.address ?? '';
    _websiteController.text = model.website ?? '';
    _noteController.text = model.privateNote;
    _worksAtContactId = model.worksAtContactId;
    _loaded = true;
  }

  bool get _dirty {
    final o = _original;
    if (o == null) return false;
    return _draftFromControllers(o).buildPatchComparedTo(o).isNotEmpty;
  }

  PeopleContactModel _draftFromControllers(PeopleContactModel base) {
    return PeopleContactModel(
      id: base.id,
      kind: base.kind,
      name: _nameController.text.trim(),
      roles: base.roles,
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      website: _websiteController.text.trim(),
      privateNote: _noteController.text.trim(),
      inactiveAt: base.inactiveAt,
      legacyVetId: base.legacyVetId,
      worksAtContactId: _worksAtContactId,
    );
  }

  Future<void> _save(PeopleContactModel base) async {
    final draft = _draftFromControllers(base);
    final patch = draft.buildPatchComparedTo(base);
    if (patch.isEmpty) {
      if (mounted) context.pop(true);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(peopleContactsProvider.notifier)
          .updateContactPatch(base.id, patch);
      if (mounted) context.pop(true);
    } on HttpException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_saveErrorMessage(context, e))));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.peopleSaveError),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _markInactive(PeopleContactModel base) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.peopleMarkInactive),
        content: Text(l.peopleMarkInactiveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.peopleMarkInactive),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await ref.read(peopleContactsProvider.notifier).updateContactPatch(
        base.id,
        {'inactive_at': DateTime.now().toUtc().toIso8601String()},
      );
      if (mounted) context.pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.peopleSaveError)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmRemove(String name, PeopleContactModel base) async {
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
    try {
      await ref
          .read(peopleContactsProvider.notifier)
          .deleteContact(widget.personId);
      if (mounted) context.go('/pc/people');
    } on HttpException catch (e) {
      final status = _peopleApiStatusCode(e);
      final message = status == 400 || status == 409
          ? l.peopleRemoveVetLinkedError
          : l.peopleRemoveError;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.peopleRemoveError)));
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_dirty) return true;
    return confirmDiscardFormChanges(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final detailAsync = ref.watch(peopleContactDetailProvider(widget.personId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _onWillPop() && context.mounted) {
          context.pop();
        }
      },
      child: detailAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(title: Text(l.peopleEditPerson)),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => Scaffold(
          appBar: AppBar(title: Text(l.peopleEditPerson)),
          body: Center(child: Text(l.peopleListLoadError)),
        ),
        data: (contact) {
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
            worksAtContactId: contact.worksAtContactId,
          );
          _loadFromContact(model);
          final organisations =
              ref
                  .watch(peopleContactsProvider)
                  .valueOrNull
                  ?.where(
                    (c) => c.kind == 'organisation' && c.inactiveAt == null,
                  )
                  .toList() ??
              const <PeopleContact>[];

          return Scaffold(
            appBar: AppBar(
              title: Text(l.peopleEditPerson),
              actions: [
                TextButton(
                  onPressed: _saving || !_dirty ? null : () => _save(model),
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
                if (model.legacyVetId != null) ...[
                  Text(
                    l.peopleVetLinkedHelper,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: l.peopleNameLabel),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                if (model.kind == 'person' && organisations.isNotEmpty)
                  DropdownButtonFormField<String?>(
                    initialValue: _worksAtContactId,
                    decoration: InputDecoration(
                      labelText: l.peopleWorksAtLabel,
                    ),
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
                if (model.kind == 'person' && organisations.isNotEmpty)
                  const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: l.peoplePhoneLabel,
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: l.peopleEmailLabel,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: l.peopleAddressLabel,
                    prefixIcon: const Icon(Icons.location_on_outlined),
                  ),
                  minLines: 2,
                  maxLines: 4,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _websiteController,
                  decoration: InputDecoration(
                    labelText: l.peopleWebsiteLabel,
                    prefixIcon: const Icon(Icons.language_outlined),
                  ),
                  keyboardType: TextInputType.url,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: l.peoplePrivateNoteLabel,
                    helperText: l.peoplePrivateNoteHelper,
                  ),
                  minLines: 2,
                  maxLines: 5,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 32),
                Text(
                  l.peopleDangerZoneTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                if (contact.inactiveAt == null)
                  OutlinedButton.icon(
                    onPressed: _saving ? null : () => _markInactive(model),
                    icon: const Icon(Icons.pause_circle_outline),
                    label: Text(l.peopleMarkInactive),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const Key('people_edit_remove_contact'),
                  onPressed: () => _confirmRemove(contact.name, model),
                  icon: const Icon(Icons.person_remove_outlined),
                  label: Text(l.peopleRemoveContactConfirm),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

int? _peopleApiStatusCode(HttpException e) {
  final match = RegExp(r'People API (\d+):').firstMatch(e.message);
  return match != null ? int.tryParse(match.group(1)!) : null;
}

String _saveErrorMessage(BuildContext context, HttpException e) {
  final l = AppLocalizations.of(context)!;
  final status = _peopleApiStatusCode(e);
  if (status == 400) {
    return l.peopleSaveValidationError;
  }
  return l.peopleSaveError;
}
