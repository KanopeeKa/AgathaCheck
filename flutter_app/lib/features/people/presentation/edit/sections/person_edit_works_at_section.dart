import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/form/app_form_section.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/contact_summary.dart';
import '../../../domain/enums/contact_group.dart';
import '../../../domain/enums/contact_kind.dart';
import '../../../domain/enums/contact_status.dart';
import '../../../domain/services/people_query.dart';
import '../../picker/people_picker_field.dart';
import '../../picker/people_picker_result.dart';
import '../person_form_controller.dart';

class PersonEditWorksAtSection extends ConsumerWidget {
  const PersonEditWorksAtSection({
    super.key,
    required this.controller,
    required this.rosterContacts,
  });

  final PersonFormController controller;
  final List<ContactSummary> rosterContacts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    if (controller.kind != ContactKind.person) {
      return const SizedBox.shrink();
    }

    final organisations = rosterContacts
        .where(
          (c) =>
              c.kind == ContactKind.organisation &&
              c.status == ContactStatus.active,
        )
        .toList();
    if (organisations.isEmpty) return const SizedBox.shrink();

    final selected = organisations
        .where((c) => c.id == controller.worksAtContactId)
        .firstOrNull;

    return AppFormSection(
      title: l.peopleWorksAtLabel,
      children: [
        PeoplePickerField(
          purpose: 'works_at',
          query: PeopleQuery(
            kinds: const {ContactKind.organisation},
            groups: const {ContactGroup.professional},
          ),
          value: selected,
          placeholder: l.peopleWorksAtNone,
          quickAddGroup: ContactGroup.professional,
          onChanged: (PeoplePickerResult? result) {
            switch (result) {
              case PeoplePickerContactResult(:final contact):
                controller.setWorksAtContactId(contact.id);
              case PeoplePickerNoneResult():
                controller.setWorksAtContactId(null);
              case null:
              case PeoplePickerTypedNameResult():
                break;
            }
          },
        ),
      ],
    );
  }
}
