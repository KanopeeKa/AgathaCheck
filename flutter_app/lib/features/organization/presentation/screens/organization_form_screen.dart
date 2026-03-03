import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/organization.dart';
import '../providers/organization_providers.dart';

class OrganizationFormScreen extends ConsumerStatefulWidget {
  const OrganizationFormScreen({super.key, this.orgId});

  final int? orgId;

  @override
  ConsumerState<OrganizationFormScreen> createState() =>
      _OrganizationFormScreenState();
}

class _OrganizationFormScreenState
    extends ConsumerState<OrganizationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _websiteController = TextEditingController();
  final _bioController = TextEditingController();
  OrganizationType _selectedType = OrganizationType.professional;
  bool _saving = false;

  bool get _isEditing => widget.orgId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      Future.microtask(_loadOrgData);
    }
  }

  void _loadOrgData() {
    final orgsAsync = ref.read(organizationListProvider);
    orgsAsync.whenData((orgs) {
      final org = orgs.where((o) => o.id == widget.orgId).firstOrNull;
      if (org != null) {
        setState(() {
          _nameController.text = org.name;
          _emailController.text = org.email;
          _phoneController.text = org.phone;
          _addressController.text = org.address;
          _websiteController.text = org.website;
          _bioController.text = org.bio;
          _selectedType = org.type;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final l = AppLocalizations.of(context)!;
    final data = {
      'name': _nameController.text.trim(),
      'type': _selectedType.name,
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'website': _websiteController.text.trim(),
      'bio': _bioController.text.trim(),
    };

    try {
      if (_isEditing) {
        await ref
            .read(organizationListProvider.notifier)
            .updateOrganization(widget.orgId!, data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.orgUpdated)),
          );
          context.pop();
        }
      } else {
        final org = await ref
            .read(organizationListProvider.notifier)
            .createOrganization(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.orgCreated)),
          );
          context.go('/organizations/${org.id}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _localizedTypeLabel(AppLocalizations l, OrganizationType type) {
    switch (type) {
      case OrganizationType.professional:
        return l.orgTypeProfessional;
      case OrganizationType.charity:
        return l.orgTypeCharity;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l.editOrganization : l.createOrganization),
        leading: IconButton(
          key: const Key('org_form_back'),
          icon: const Icon(Icons.arrow_back),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    key: const Key('org_name_field'),
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: '${l.organizationName} *',
                      prefixIcon: const Icon(Icons.business),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return l.orgNameRequired;
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<OrganizationType>(
                    key: const Key('org_type_dropdown'),
                    value: _selectedType,
                    decoration: InputDecoration(
                      labelText: l.organizationType,
                      prefixIcon: const Icon(Icons.category),
                    ),
                    items: OrganizationType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(_localizedTypeLabel(l, type)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('org_email_field'),
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: l.orgEmail,
                      prefixIcon: const Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('org_phone_field'),
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: l.orgPhone,
                      prefixIcon: const Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('org_address_field'),
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: l.orgAddress,
                      prefixIcon: const Icon(Icons.location_on),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('org_website_field'),
                    controller: _websiteController,
                    decoration: InputDecoration(
                      labelText: l.orgWebsite,
                      prefixIcon: const Icon(Icons.language),
                    ),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('org_bio_field'),
                    controller: _bioController,
                    decoration: InputDecoration(
                      labelText: l.orgBio,
                      prefixIcon: const Icon(Icons.description),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('org_save_button'),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(_isEditing ? l.editOrganization : l.createOrganization),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
