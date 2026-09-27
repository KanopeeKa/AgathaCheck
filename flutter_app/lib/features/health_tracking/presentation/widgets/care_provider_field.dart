import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../people/presentation/providers/people_providers.dart';

/// Default provider on a care item: contact picker or interim typed name (D-CIE-016).
class CareProviderField extends ConsumerStatefulWidget {
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
  ConsumerState<CareProviderField> createState() => _CareProviderFieldState();
}

class _CareProviderFieldState extends ConsumerState<CareProviderField> {
  late final TextEditingController _typedController;
  bool _useTyped = false;

  @override
  void initState() {
    super.initState();
    _useTyped = widget.typedName != null && widget.typedName!.isNotEmpty;
    _typedController = TextEditingController(text: widget.typedName ?? '');
  }

  @override
  void dispose() {
    _typedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final contactsAsync = ref.watch(peopleContactsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.careProviderLabel,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l.careProviderUseTypedName),
          value: _useTyped,
          onChanged: (v) {
            setState(() {
              _useTyped = v;
              if (v) {
                widget.onChanged(
                  contactId: null,
                  typedName: _typedController.text.trim(),
                );
              } else {
                widget.onChanged(contactId: widget.contactId, typedName: null);
              }
            });
          },
        ),
        if (_useTyped)
          TextField(
            controller: _typedController,
            decoration: InputDecoration(labelText: l.careProviderTypedName),
            onChanged: (v) =>
                widget.onChanged(contactId: null, typedName: v.trim()),
          )
        else
          contactsAsync.when(
            data: (contacts) {
              return DropdownButtonFormField<String?>(
                value: widget.contactId,
                decoration: InputDecoration(
                  labelText: l.careProviderChooseContact,
                ),
                items: [
                  DropdownMenuItem<String?>(value: null, child: Text(l.none)),
                  ...contacts.map(
                    (c) => DropdownMenuItem<String?>(
                      value: c.id,
                      child: Text(c.name),
                    ),
                  ),
                ],
                onChanged: (id) =>
                    widget.onChanged(contactId: id, typedName: null),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => Text(l.careProviderContactsUnavailable),
          ),
      ],
    );
  }
}
