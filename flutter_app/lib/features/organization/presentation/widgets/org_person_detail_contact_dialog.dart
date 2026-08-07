import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/org_person.dart';

class FosterContactEditResult {
  const FosterContactEditResult({
    required this.fosterPhone,
    required this.fosterAddress,
    required this.adminNotes,
    this.displayName,
    this.email,
  });

  final String fosterPhone;
  final String fosterAddress;
  final String adminNotes;
  final String? displayName;
  final String? email;
}

Future<FosterContactEditResult?> promptFosterContactEdit({
  required BuildContext context,
  required OrgPersonDetail person,
}) async {
  final l = AppLocalizations.of(context)!;
  final phoneController = TextEditingController(text: person.fosterPhone);
  final addressController = TextEditingController(text: person.fosterAddress);
  final notesController = TextEditingController(text: person.adminNotes);
  final nameController = TextEditingController(text: person.displayName);
  final emailController = TextEditingController(text: person.email ?? '');

  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.editFosterContact),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (person.isExternal) ...[
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l.fosterParentDisplayName,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: l.email),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: phoneController,
              decoration: InputDecoration(labelText: l.phone),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: addressController,
              decoration: InputDecoration(labelText: l.fosterContactAddress),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: l.notes,
                helperText: l.orgNotesOperationalOnly,
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l.save),
        ),
      ],
    ),
  );

  if (saved != true) {
    phoneController.dispose();
    addressController.dispose();
    notesController.dispose();
    nameController.dispose();
    emailController.dispose();
    return null;
  }

  final result = FosterContactEditResult(
    fosterPhone: phoneController.text.trim(),
    fosterAddress: addressController.text.trim(),
    adminNotes: notesController.text.trim(),
    displayName: person.isExternal ? nameController.text.trim() : null,
    email: person.isExternal ? emailController.text.trim() : null,
  );

  phoneController.dispose();
  addressController.dispose();
  notesController.dispose();
  nameController.dispose();
  emailController.dispose();
  return result;
}
