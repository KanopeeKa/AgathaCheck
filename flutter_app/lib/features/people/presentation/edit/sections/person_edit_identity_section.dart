import 'package:flutter/material.dart';

import '../../../../../core/widgets/form/app_form_labeled_field.dart';
import '../../../../../core/widgets/form/app_form_section.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/enums/contact_kind.dart';
import '../../../domain/enums/contact_role.dart';
import '../../labels/people_labels.dart';
import '../../widgets/role_chips.dart';
import '../person_form_controller.dart';

class PersonEditIdentitySection extends StatelessWidget {
  const PersonEditIdentitySection({super.key, required this.controller});

  final PersonFormController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final linked = controller.isLinked;

    return AppFormSection(
      title: l.peopleEditSectionIdentity,
      children: [
        if (linked)
          Text(
            l.peopleEditLinkedReadOnlyHelper,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        if (linked) const SizedBox(height: 12),
        AppFormLabeledField(
          label: l.peopleNameLabel,
          child: TextFormField(
            key: const Key('people_edit_name_field'),
            initialValue: controller.name,
            enabled: !linked,
            decoration: InputDecoration(
              errorText: controller.nameError == null
                  ? null
                  : l.peopleNameRequired,
            ),
            onChanged: controller.setName,
            validator: (v) =>
                v == null || v.trim().isEmpty ? l.peopleNameRequired : null,
          ),
        ),
        const SizedBox(height: 16),
        AppFormLabeledField(
          label: l.peopleKindLabel,
          isTextField: false,
          child: SegmentedButton<ContactKind>(
            segments: [
              ButtonSegment(
                value: ContactKind.person,
                label: Text(l.peopleKindPerson),
              ),
              ButtonSegment(
                value: ContactKind.organisation,
                label: Text(l.peopleKindOrganisation),
              ),
            ],
            selected: {controller.kind},
            onSelectionChanged: linked
                ? null
                : (value) => controller.setKind(value.first),
          ),
        ),
        const SizedBox(height: 16),
        RoleChips(
          mode: RoleChipsMode.groupedSelect,
          roles: ContactRole.values,
          selected: controller.roles,
          onToggle: linked ? null : controller.toggleRole,
        ),
      ],
    );
  }
}
