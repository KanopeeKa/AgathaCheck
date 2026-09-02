import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../domain/entities/vet.dart';
import '../providers/vet_providers.dart';

class VetFormScreen extends ConsumerStatefulWidget {
  const VetFormScreen({
    super.key,
    this.vetId,
    this.listPath = '/pc/vets',
    this.defaultOrganizationId,
  });

  final String? vetId;
  final String listPath;
  final String? defaultOrganizationId;

  @override
  ConsumerState<VetFormScreen> createState() => _VetFormScreenState();
}

class _VetFormScreenState extends ConsumerState<VetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  bool _isEdit = false;
  String? _organizationId;

  @override
  void initState() {
    super.initState();
    _organizationId = widget.defaultOrganizationId;
    if (widget.vetId != null) {
      _isEdit = true;
      _loadVet();
    }
  }

  Future<void> _loadVet() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(vetRepositoryProvider);
      final vet = await repo.getVet(widget.vetId!);
      if (vet != null && mounted) {
        setState(() {
          _nameController.text = vet.name;
          _phoneController.text = vet.phone;
          _emailController.text = vet.email;
          _websiteController.text = vet.website;
          _addressController.text = vet.address;
          _notesController.text = vet.notes;
          _organizationId = vet.organizationId;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load vet: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: AppLogoTitle(title: _isEdit ? l.editVet : l.addVet),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l.backToVets,
          onPressed: () => context.go(widget.listPath),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        key: const Key('vet_name_field'),
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: l.vetName,
                          prefixIcon: const Icon(Icons.person),
                        ),
                        autofillHints: const [AutofillHints.name],
                        validator: (val) => val == null || val.trim().isEmpty
                            ? l.vetNameRequired
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('vet_phone_field'),
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: l.phone,
                          prefixIcon: const Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        autofillHints: const [AutofillHints.telephoneNumber],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('vet_email_field'),
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: l.vetEmail,
                          prefixIcon: const Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('vet_website_field'),
                        controller: _websiteController,
                        decoration: InputDecoration(
                          labelText: l.website,
                          prefixIcon: const Icon(Icons.language),
                        ),
                        keyboardType: TextInputType.url,
                        autofillHints: const [AutofillHints.url],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('vet_address_field'),
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: l.address,
                          prefixIcon: const Icon(Icons.location_on),
                        ),
                        autofillHints: const [AutofillHints.fullStreetAddress],
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('vet_notes_field'),
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: l.vetNotes,
                          prefixIcon: const Icon(Icons.notes),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                      ),
                      if (_isEdit) ...[
                        const SizedBox(height: 24),
                        _LinkedPetsSection(vetId: widget.vetId!),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          key: const Key('delete_vet_button'),
                          onPressed: _isLoading
                              ? null
                              : () => _confirmDelete(context, l),
                          icon: const Icon(Icons.delete_outline),
                          label: Text(l.deleteVet),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        key: const Key('save_vet_button'),
                        onPressed: _isLoading ? null : _submit,
                        icon: Icon(_isEdit ? Icons.save : Icons.add),
                        label: Text(_isEdit ? l.save : l.addVet),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final vet = Vet(
        id: widget.vetId ?? '',
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        website: _websiteController.text.trim(),
        address: _addressController.text.trim(),
        notes: _notesController.text.trim(),
        organizationId: _organizationId,
      );

      final notifier = ref.read(vetListProvider.notifier);
      if (_isEdit) {
        await notifier.updateVet(vet);
      } else {
        await notifier.createVet(vet);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'Vet updated' : 'Vet added')),
        );
        context.go(widget.listPath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete(BuildContext context, AppLocalizations l) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteVet),
        content: Text(l.deleteVetConfirm(_nameController.text.trim())),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(vetListProvider.notifier).deleteVet(widget.vetId!);
      if (mounted) context.go(widget.listPath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _LinkedPetsSection extends ConsumerWidget {
  const _LinkedPetsSection({required this.vetId});

  final String vetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(petListProvider);
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.pets, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              l.linkedPets,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        petsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Could not load pets: $e'),
          data: (pets) {
            if (pets.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l.noPetsAddFirst,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }

            final linked = pets.where((p) => p.vetId == vetId).toList();
            final unlinked = pets.where((p) => p.vetId != vetId).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (linked.isNotEmpty) ...[
                  ...linked.map(
                    (pet) => Card(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.pets,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(pet.name),
                        subtitle: Text(pet.species),
                        trailing: TextButton.icon(
                          icon: const Icon(Icons.link_off, size: 18),
                          label: Text(l.unlink),
                          onPressed: () => _unlinkPet(ref, pet),
                        ),
                      ),
                    ),
                  ),
                ],
                if (unlinked.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    l.availablePets,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...unlinked.map(
                    (pet) => Card(
                      margin: const EdgeInsets.only(bottom: 4),
                      color: theme.colorScheme.surfaceContainerLow,
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.pets,
                          color: theme.colorScheme.outline,
                        ),
                        title: Text(pet.name),
                        subtitle: Text(pet.species),
                        trailing: TextButton.icon(
                          icon: const Icon(Icons.link, size: 18),
                          label: Text(l.link),
                          onPressed: () => _linkPet(ref, pet),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _linkPet(WidgetRef ref, Pet pet) async {
    final updated = pet.copyWith(vetId: vetId);
    await ref.read(petListProvider.notifier).updatePet(updated);
  }

  Future<void> _unlinkPet(WidgetRef ref, Pet pet) async {
    final updated = pet.copyWith(clearVetId: true);
    await ref.read(petListProvider.notifier).updatePet(updated);
  }
}
