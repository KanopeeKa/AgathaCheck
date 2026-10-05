import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/contact_summary.dart';
import '../../domain/enums/contact_group.dart';
import '../../domain/services/people_query.dart';
import '../labels/people_labels.dart';
import '../widgets/person_avatar.dart';
import 'people_picker_result.dart';
import 'people_picker_sheet.dart';

/// Form field that opens [PeoplePickerSheet] for a contact choice.
class PeoplePickerField extends ConsumerWidget {
  const PeoplePickerField({
    super.key,
    required this.purpose,
    required this.query,
    this.value,
    this.placeholder,
    required this.onChanged,
    this.quickAddGroup,
  });

  final String purpose;
  final PeopleQuery query;
  final ContactSummary? value;
  final String? placeholder;
  final ValueChanged<PeoplePickerResult?> onChanged;
  final ContactGroup? quickAddGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final label = value == null
        ? (placeholder ?? l.peoplePickerPlaceholder)
        : value!.name;
    final subtitle = value == null ? null : contactRolesLine(l, value!.roles);

    return Semantics(
      identifier: 'people_picker_field_$purpose',
      button: true,
      label: label,
      child: InkWell(
        onTap: () => _open(context, ref),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: l.peoplePickerFieldLabel,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.expand_more),
          ),
          child: Row(
            children: [
              if (value != null) ...[
                personAvatarFromSummary(value!),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label),
                    if (subtitle != null && subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final result = await showPeoplePickerSheet(
      context: context,
      ref: ref,
      query: query,
      purpose: purpose,
      quickAddGroup: quickAddGroup ?? ContactGroup.carer,
    );
    onChanged(result);
  }
}
