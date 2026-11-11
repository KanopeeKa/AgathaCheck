import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../labels/people_labels.dart';
import 'add_person_app_access.dart';
import 'add_person_entry.dart';
import 'add_person_flow_controller.dart';

class AddPersonStepAppAccess extends StatelessWidget {
  const AddPersonStepAppAccess({super.key, required this.controller});

  final AddPersonFlowController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final entry = controller.entry!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.peopleAddAppAccessTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          l.peopleAddAppAccessBody,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        RadioGroup<AddPersonAppAccessChoice>(
          groupValue: controller.appAccess,
          onChanged: (v) {
            if (v != null) controller.setAppAccess(v);
          },
          child: Column(
            children: [
              RadioListTile(
                value: AddPersonAppAccessChoice.skip,
                title: Text(l.peopleAddAppAccessSkip),
              ),
              if (entry == AddPersonEntry.carer) ...[
                RadioListTile(
                  value: AddPersonAppAccessChoice.sharePets,
                  title: Text(l.peopleAddAppAccessShare),
                ),
                RadioListTile(
                  value: AddPersonAppAccessChoice.absenceInvite,
                  title: Text(l.peopleAddAppAccessAbsence),
                ),
              ],
              if (entry == AddPersonEntry.household) ...[
                RadioListTile(
                  value: AddPersonAppAccessChoice.householdInvite,
                  title: Text(l.peopleAddAppAccessHousehold),
                ),
              ],
            ],
          ),
        ),
        if (controller.appAccess == AddPersonAppAccessChoice.householdInvite)
          TextFormField(
            decoration: InputDecoration(labelText: l.peopleAddHouseholdName),
            onChanged: controller.setHouseholdName,
          ),
        const SizedBox(height: 24),
        AddPersonStepReview(controller: controller),
      ],
    );
  }
}

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

class AddPersonStepReview extends StatelessWidget {
  const AddPersonStepReview({super.key, required this.controller});

  final AddPersonFlowController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final form = controller.form;
    return ListenableBuilder(
      listenable: form,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.peopleAddStepReview,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(form.name, style: Theme.of(context).textTheme.titleSmall),
            if (form.roles.isNotEmpty)
              Text(contactRolesLine(l, form.roles.toList())),
          ],
        );
      },
    );
  }
}
