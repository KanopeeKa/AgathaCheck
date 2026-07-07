import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/organization_providers.dart';

Future<void> showOrganizationAddFosterParentDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String orgId,
}) async {
  final l = AppLocalizations.of(context)!;
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final notesController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var lawfulBasisConfirmed = false;

  final created = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(l.addExternalFoster),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l.addFosterParentDescription,
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l.fosterParentDisplayName,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l.orgNameRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: l.email),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l.emailRequiredForExternalFoster;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: l.phone),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: addressController,
                  decoration: InputDecoration(
                    labelText: l.fosterContactAddress,
                  ),
                  textInputAction: TextInputAction.next,
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: l.notes,
                    helperText: l.orgNotesOperationalOnly,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: lawfulBasisConfirmed,
                  onChanged: (value) {
                    setState(() => lawfulBasisConfirmed = value == true);
                  },
                  title: Text(
                    l.lawfulBasisConfirm,
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              if (!lawfulBasisConfirmed) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(l.lawfulBasisConfirmRequired)),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: Text(l.addFosterParent),
          ),
        ],
      ),
    ),
  );

  if (created != true) {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    notesController.dispose();
    return;
  }

  try {
    await ref
        .read(orgPeopleProvider(orgId).notifier)
        .createExternal(
          displayName: nameController.text.trim(),
          email: emailController.text.trim(),
          phone: phoneController.text.trim().isEmpty
              ? null
              : phoneController.text.trim(),
          fosterAddress: addressController.text.trim(),
          notes: notesController.text.trim(),
          lawfulBasisConfirmed: true,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.externalFosterNoticeSent)));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  } finally {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    notesController.dispose();
  }
}
