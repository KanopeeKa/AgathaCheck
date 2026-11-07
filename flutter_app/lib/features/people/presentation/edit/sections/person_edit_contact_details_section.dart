import 'package:flutter/material.dart';

import '../../../../../core/widgets/form/app_form_labeled_field.dart';
import '../../../../../core/widgets/form/app_form_section.dart';
import '../../../../../l10n/app_localizations.dart';
import '../person_form_controller.dart';

/// Phone field must use a [TextEditingController] on web — `initialValue` + CanvasKit can leave the
/// hidden `<input>` out of sync with [PersonFormController], so saves keep the old number (E2E).
class _PersonEditPhoneField extends StatefulWidget {
  const _PersonEditPhoneField({required this.controller, required this.label});

  final PersonFormController controller;
  final String label;

  @override
  State<_PersonEditPhoneField> createState() => _PersonEditPhoneFieldState();
}

class _PersonEditPhoneFieldState extends State<_PersonEditPhoneField> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.controller.phone);
    // Do not listen to [ChangeNotifier] here: other fields call `notifyListeners` while the user
    // types; resetting `_textController` from `controller.phone` in those ticks races `onChanged`
    // and can snap the web `<input>` back to the old digits (E2E / automation).
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppFormLabeledField(
      label: widget.label,
      isTextField: false,
      child: Semantics(
        identifier: 'people_edit_phone_field',
        label: widget.label,
        textField: true,
        child: TextFormField(
          key: const Key('people_edit_phone_field'),
          controller: _textController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          onChanged: widget.controller.setPhone,
        ),
      ),
    );
  }
}

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
        _PersonEditPhoneField(
          controller: controller,
          label: l.peoplePhoneLabel,
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
