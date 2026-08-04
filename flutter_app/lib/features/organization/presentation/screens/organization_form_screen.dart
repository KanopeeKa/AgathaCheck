import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/organization.dart';
import '../controllers/org_dashboard_menu.dart';
import '../providers/organization_providers.dart';
import '../widgets/org_permission_gate.dart';
import '../widgets/org_shell_app_bar_title.dart';
import '../widgets/org_shell_scaffold.dart';
import '../widgets/organization_branding_section.dart';

class OrganizationFormScreen extends ConsumerStatefulWidget {
  const OrganizationFormScreen({super.key, this.orgId});

  final String? orgId;

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
  final _townController = TextEditingController();
  final _administrativeAreaController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _websiteController = TextEditingController();
  final _bioController = TextEditingController();
  OrganizationType _selectedType = OrganizationType.professional;
  bool _saving = false;
  String? _populatedOrgId;

  bool get _isEditing => widget.orgId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      Future.microtask(_loadOrgData);
    }
  }

  void _populateFromOrg(Organization org) {
    if (_populatedOrgId == org.id) return;
    _populatedOrgId = org.id;
    _nameController.text = org.name;
    _emailController.text = org.email;
    _phoneController.text = org.phone;
    _addressController.text = org.address;
    _townController.text = org.town;
    _administrativeAreaController.text = org.administrativeArea;
    _postcodeController.text =
        org.publicProfileMetadata['postcode']?.toString() ?? '';
    _websiteController.text = org.website;
    _bioController.text = org.bio;
    _selectedType = org.type;
  }

  void _loadOrgData() {
    final orgsAsync = ref.read(organizationListProvider);
    orgsAsync.whenData((orgs) {
      final org = orgs.where((o) => o.id == widget.orgId).firstOrNull;
      if (org != null) {
        setState(() => _populateFromOrg(org));
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _townController.dispose();
    _administrativeAreaController.dispose();
    _postcodeController.dispose();
    _websiteController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final l = AppLocalizations.of(context)!;
    final postcode = _postcodeController.text.trim();
    final data = {
      'name': _nameController.text.trim(),
      'type': _selectedType == OrganizationType.charity
          ? 'charity'
          : 'professional',
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'town': _townController.text.trim(),
      'administrative_area': _administrativeAreaController.text.trim(),
      'website': _websiteController.text.trim(),
      'bio': _bioController.text.trim(),
      if (postcode.isNotEmpty)
        'public_profile_metadata': {'postcode': postcode},
    };

    try {
      if (_isEditing) {
        await ref
            .read(organizationListProvider.notifier)
            .updateOrganization(widget.orgId!, data);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l.orgUpdated)));
          context.pop();
        }
      } else {
        final org = await ref
            .read(organizationListProvider.notifier)
            .createOrganization(data);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l.orgCreated)));
          context.go('/o/orgs/${org.id}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _nameValidator(String? value) {
    final l = AppLocalizations.of(context)!;
    if (value == null || value.trim().isEmpty) {
      return l.orgNameRequired;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final orgsAsync = ref.watch(organizationListProvider);

    if (_isEditing) {
      ref.listen(organizationListProvider, (_, next) {
        next.whenData((orgs) {
          final org = orgs.where((o) => o.id == widget.orgId).firstOrNull;
          if (org != null) {
            setState(() => _populateFromOrg(org));
          }
        });
      });
    }

    final editingOrg = _isEditing
        ? orgsAsync.maybeWhen(
            data: (orgs) => orgs.where((o) => o.id == widget.orgId).firstOrNull,
            orElse: () => null,
          )
        : null;

    return OrgShellScaffold(
      key: const Key('org_form_screen'),
      title: _isEditing ? l.editOrganization : l.createOrganization,
      orgId: widget.orgId,
      navVariant: widget.orgId != null
          ? OrgNavTitleVariant.withOrgLogo
          : OrgNavTitleVariant.textOnly,
      leadingKey: const Key('org_form_back'),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: _isEditing ? 0 : 16,
          bottom: 24,
          left: _isEditing ? 0 : 16,
          right: _isEditing ? 0 : 16,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (editingOrg != null) ...[
                      OrganizationBrandingSection(
                        org: editingOrg,
                        theme: theme,
                        colorScheme: colorScheme,
                        l: l,
                        nameController: _nameController,
                        selectedType: _selectedType,
                        onTypeChanged: (value) =>
                            setState(() => _selectedType = value),
                        nameValidator: _nameValidator,
                      ),
                      const SizedBox(height: 16),
                    ],
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: _isEditing ? 16 : 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!_isEditing) ...[
                            TextFormField(
                              key: const Key('org_name_field'),
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: '${l.organizationName} *',
                                prefixIcon: const Icon(Icons.business),
                              ),
                              autofillHints: const [
                                AutofillHints.organizationName,
                              ],
                              validator: _nameValidator,
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
                          ],
                          TextFormField(
                            key: const Key('org_email_field'),
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: l.orgEmail,
                              prefixIcon: const Icon(Icons.email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
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
                            autofillHints: const [AutofillHints.telephoneNumber],
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
                            autofillHints: const [
                              AutofillHints.fullStreetAddress,
                            ],
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            key: const Key('org_town_field'),
                            controller: _townController,
                            decoration: InputDecoration(
                              labelText: l.orgTown,
                              prefixIcon: const Icon(Icons.location_city),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            key: const Key('org_administrative_area_field'),
                            controller: _administrativeAreaController,
                            decoration: InputDecoration(
                              labelText: l.orgAdministrativeArea,
                              prefixIcon: const Icon(Icons.map_outlined),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            key: const Key('org_postcode_field'),
                            controller: _postcodeController,
                            decoration: InputDecoration(
                              labelText: l.orgPostcode,
                              prefixIcon: const Icon(
                                Icons.markunread_mailbox_outlined,
                              ),
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
                            autofillHints: const [AutofillHints.url],
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
                          if (_isEditing)
                            OrgPermissionGate(
                              orgId: widget.orgId!,
                              permissionKey: 'manage_permissions',
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: OutlinedButton.icon(
                                  key: const Key('org_customisations_entry'),
                                  icon: const Icon(Icons.tune),
                                  label: Text(l.orgCustomisationsTitle),
                                  onPressed: () => context.push(
                                    '/o/orgs/${widget.orgId}/customisations',
                                  ),
                                ),
                              ),
                            ),
                          FilledButton(
                            key: const Key('org_save_button'),
                            onPressed: _saving ? null : _save,
                            child: _saving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _isEditing
                                        ? l.editOrganization
                                        : l.createOrganization,
                                  ),
                          ),
                          if (_isEditing && editingOrg != null)
                            OrgPermissionGate(
                              orgId: widget.orgId!,
                              permissionKey: 'manage_permissions',
                              child: Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: OutlinedButton.icon(
                                  key: const Key('org_delete_button'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: colorScheme.error,
                                    side: BorderSide(color: colorScheme.error),
                                  ),
                                  icon: const Icon(Icons.delete_outline),
                                  label: Text(l.deleteOrganization),
                                  onPressed: () => showOrgDeleteDialog(
                                    context: context,
                                    ref: ref,
                                    orgId: widget.orgId!,
                                    org: editingOrg,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _localizedTypeLabel(AppLocalizations l, OrganizationType type) {
    switch (type) {
      case OrganizationType.professional:
        return l.orgTypeProfessional;
      case OrganizationType.charity:
        return l.orgTypeCharity;
    }
  }
}
