import 'package:flutter/material.dart';

import '../../../../../core/widgets/form/app_form_labeled_field.dart';
import '../../../../../core/widgets/form/app_form_section.dart';
import '../../../../../l10n/app_localizations.dart';
import '../person_form_controller.dart';

class PersonEditContactDetailsSection extends StatelessWidget {
  const PersonEditContactDetailsSection({super.key, required this.controller});

  final PersonFormController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final linked = controller.isLinked;

    return AppFormSection(
      title: l.peopleEditSectionContact,
      children: [
        AppFormLabeledField(
          label: l.peoplePhoneLabel,
          child: TextFormField(
            key: const Key('people_edit_phone_field'),
            initialValue: controller.phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            onChanged: controller.setPhone,
          ),
        ),
        const SizedBox(height: 16),
        AppFormLabeledField(
          label: l.peopleEmailLabel,
          child: TextFormField(
            key: const Key('people_edit_email_field'),
            initialValue: controller.email,
            enabled: !linked,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.email_outlined),
              errorText: controller.emailError == null
                  ? null
                  : l.peopleEmailInvalid,
            ),
            onChanged: controller.setEmail,
          ),
        ),
        const SizedBox(height: 16),
        AppFormLabeledField(
          label: l.peopleAddressLabel,
          child: TextFormField(
            initialValue: controller.address,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            minLines: 2,
            maxLines: 4,
            onChanged: controller.setAddress,
          ),
        ),
        const SizedBox(height: 16),
        AppFormLabeledField(
          label: l.peopleWebsiteLabel,
          child: TextFormField(
            initialValue: controller.website,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.language_outlined),
            ),
            onChanged: controller.setWebsite,
          ),
        ),
      ],
    );
  }
}
