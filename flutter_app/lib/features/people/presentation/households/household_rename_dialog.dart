import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

Future<String?> showHouseholdRenameDialog(
  BuildContext context, {
  required String initialName,
}) {
  final l = AppLocalizations.of(context)!;
  final formKey = GlobalKey<FormState>();
  return showDialog<String>(
    context: context,
    builder: (ctx) {
      final controller = TextEditingController(text: initialName);
      return AlertDialog(
        title: Text(l.peopleHouseholdRenameTitle),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(labelText: l.householdNameLabel),
            autofocus: true,
            validator: (value) => value == null || value.trim().isEmpty
                ? l.householdNameRequired
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, controller.text.trim());
              }
            },
            child: Text(l.save),
          ),
        ],
      );
    },
  );
}
