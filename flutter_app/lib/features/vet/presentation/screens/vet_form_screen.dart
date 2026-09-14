import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_logo_title.dart';
import '../../../../core/widgets/form/app_form_actions_bar.dart';
import '../../../../core/widgets/form/app_form_breakpoints.dart';
import '../../../../core/widgets/form/app_form_destructive_button.dart';
import '../../../../core/widgets/form/app_form_discard_dialog.dart';
import '../../../../core/widgets/form/app_form_labeled_field.dart';
import '../../../../core/widgets/form/app_form_section.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/vet.dart';
import '../providers/vet_providers.dart';
import '../widgets/vet_linked_pets_section.dart';

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
  Map<String, String>? _baseline;

  @override
  void initState() {
    super.initState();
    _organizationId = widget.defaultOrganizationId;
    for (final controller in [
      _nameController,
      _phoneController,
      _emailController,
      _websiteController,
      _addressController,
      _notesController,
    ]) {
      controller.addListener(_onFieldChanged);
    }
    if (widget.vetId != null) {
      _isEdit = true;
      _loadVet();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _captureBaseline());
    }
  }

  void _onFieldChanged() => setState(() {});

  Map<String, String> _snapshot() => {
    'name': _nameController.text,
    'phone': _phoneController.text,
    'email': _emailController.text,
    'website': _websiteController.text,
    'address': _addressController.text,
    'notes': _notesController.text,
  };

  void _captureBaseline() => _baseline = _snapshot();

  bool get _isDirty =>
      _baseline != null && _snapshot().toString() != _baseline!.toString();

  Future<void> _loadVet() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(vetRepositoryProvider);
      final vet = await repo.getVet(widget.vetId!);
      if (vet != null && mounted) {
        _nameController.text = vet.name;
        _phoneController.text = vet.phone;
        _emailController.text = vet.email;
        _websiteController.text = vet.website;
        _addressController.text = vet.address;
        _notesController.text = vet.notes;
        _organizationId = vet.organizationId;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load vet: $e')));
      }
    } finally {
      if (mounted) {
        _captureBaseline();
        setState(() => _isLoading = false);
      }
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

  Future<void> _handleBack() async {
    if (!_isEdit || !_isDirty) {
      context.go(widget.listPath);
      return;
    }
    if (await confirmDiscardFormChanges(context) && mounted) {
      context.go(widget.listPath);
    }
  }

  Widget _actionsBar(AppLocalizations l) {
    return AppFormActionsBar(
      isLoading: _isLoading,
      isDirty: _isEdit ? _isDirty : true,
      onSave: _submit,
      onCancel: _handleBack,
      saveLabel: _isEdit ? l.vetFormSaveChanges : l.addVet,
      cancelKey: const Key('cancel_vet_button'),
      saveKey: const Key('save_vet_button'),
      requireDirtyToSave: _isEdit,
    );
  }

  Widget _formContent(AppLocalizations l, {required bool includeActions}) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppFormSection(
            title: l.vetFormContactDetails,
            children: [
              AppFormLabeledField(
                label: l.vetName,
                child: TextFormField(
                  key: const Key('vet_name_field'),
                  controller: _nameController,
                  decoration: const InputDecoration(),
                  autofillHints: const [AutofillHints.name],
                  validator: (val) => val == null || val.trim().isEmpty
                      ? l.vetNameRequired
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              AppFormLabeledField(
                label: l.phone,
                child: TextFormField(
                  key: const Key('vet_phone_field'),
                  controller: _phoneController,
                  decoration: const InputDecoration(),
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                ),
              ),
              const SizedBox(height: 16),
              AppFormLabeledField(
                label: l.vetEmail,
                child: TextFormField(
                  key: const Key('vet_email_field'),
                  controller: _emailController,
                  decoration: const InputDecoration(),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                ),
              ),
              const SizedBox(height: 16),
              AppFormLabeledField(
                label: l.website,
                child: TextFormField(
                  key: const Key('vet_website_field'),
                  controller: _websiteController,
                  decoration: const InputDecoration(),
                  keyboardType: TextInputType.url,
                  autofillHints: const [AutofillHints.url],
                ),
              ),
              const SizedBox(height: 16),
              AppFormLabeledField(
                label: l.address,
                child: TextFormField(
                  key: const Key('vet_address_field'),
                  controller: _addressController,
                  decoration: const InputDecoration(),
                  autofillHints: const [AutofillHints.fullStreetAddress],
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppFormSection(
            title: l.vetFormNotesSection,
            children: [
              AppFormLabeledField(
                label: l.vetNotes,
                child: TextFormField(
                  key: const Key('vet_notes_field'),
                  controller: _notesController,
                  decoration: const InputDecoration(),
                  maxLines: 3,
                ),
              ),
            ],
          ),
          if (_isEdit) ...[
            const SizedBox(height: 16),
            VetLinkedPetsSection(vetId: widget.vetId!),
            const SizedBox(height: 16),
            AppFormDestructiveButton(
              buttonKey: const Key('delete_vet_button'),
              label: l.deleteVet,
              onPressed: _isLoading ? null : () => _confirmDelete(context, l),
            ),
          ],
          if (includeActions) ...[const SizedBox(height: 24), _actionsBar(l)],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isPhone =
        AppFormBreakpoints.layoutForWidth(MediaQuery.sizeOf(context).width) ==
        AppFormLayoutSize.phone;

    return PopScope(
      canPop: !_isEdit || !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await confirmDiscardFormChanges(context) && context.mounted) {
          context.go(widget.listPath);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: AppLogoTitle(title: _isEdit ? l.editVet : l.addVet),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: l.backToVets,
            onPressed: _handleBack,
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  final layout = AppFormBreakpoints.layoutForWidth(
                    constraints.maxWidth,
                  );
                  final includeActions = layout != AppFormLayoutSize.phone;
                  final form = AutofillGroup(
                    child: _formContent(l, includeActions: includeActions),
                  );
                  if (layout == AppFormLayoutSize.phone) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      child: form,
                    );
                  }
                  return Align(
                    alignment: Alignment.topCenter,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppFormBreakpoints.tabletContentMaxWidth,
                        ),
                        child: form,
                      ),
                    ),
                  );
                },
              ),
        bottomNavigationBar: isPhone && !_isLoading
            ? AppFormStickyActionsBar(
                stickyKey: const Key('vet_form_sticky_actions'),
                isLoading: _isLoading,
                isDirty: _isEdit ? _isDirty : true,
                onSave: _submit,
                onCancel: _handleBack,
                saveLabel: _isEdit ? l.vetFormSaveChanges : l.addVet,
                cancelKey: const Key('cancel_vet_button'),
                saveKey: const Key('save_vet_button'),
                requireDirtyToSave: _isEdit,
              )
            : null,
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
