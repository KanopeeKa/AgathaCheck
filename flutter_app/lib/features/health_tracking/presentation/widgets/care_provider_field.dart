import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../people/people.dart';

/// Default provider on a care item: contact picker or interim typed name (D-CIE-016).
class CareProviderField extends ConsumerWidget {
  const CareProviderField({
    super.key,
    this.contactId,
    this.typedName,
    required this.onChanged,
  });

  final String? contactId;
  final String? typedName;
  final void Function({String? contactId, String? typedName}) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final selected = contactId == null
        ? null
        : ref.watch(personSummaryProvider(contactId!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.careProviderLabel,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        PeoplePickerField(
          purpose: 'care_provider',
          query: PeopleQuery(
            allowTypedName: true,
            allowNone: true,
            currentId: contactId,
          ),
          value: typedName != null && typedName!.isNotEmpty
              ? ContactSummary(
                  id: '__typed__',
                  directory: const ContactDirectoryRef(type: 'personal'),
                  kind: ContactKind.person,
                  name: typedName!,
                  roles: const [],
                  group: ContactGroup.professional,
                  status: ContactStatus.active,
                )
              : selected,
          placeholder: l.careProviderChooseContact,
          onChanged: (PeoplePickerResult? result) {
            switch (result) {
              case PeoplePickerContactResult(:final contact):
                onChanged(contactId: contact.id, typedName: null);
              case PeoplePickerTypedNameResult(:final name):
                onChanged(contactId: null, typedName: name);
              case PeoplePickerNoneResult():
                onChanged(contactId: null, typedName: null);
              case null:
                break;
            }
          },
        ),
      ],
    );
  }
}
