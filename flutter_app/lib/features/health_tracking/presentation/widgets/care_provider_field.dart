import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Lightweight contact row for the care provider picker (no People feature import).
class CareProviderContactOption {
  const CareProviderContactOption({required this.id, required this.name});

  final String id;
  final String name;
}

/// Default provider on a care item: contact picker or interim typed name (D-CIE-016).
class CareProviderField extends StatefulWidget {
  const CareProviderField({
    super.key,
    this.contactId,
    this.typedName,
    required this.onChanged,
    this.contacts = const [],
    this.contactsLoading = false,
    this.contactsError = false,
  });

  final String? contactId;
  final String? typedName;
  final void Function({String? contactId, String? typedName}) onChanged;
  final List<CareProviderContactOption> contacts;
  final bool contactsLoading;
  final bool contactsError;

  @override
  State<CareProviderField> createState() => _CareProviderFieldState();
}

class _CareProviderFieldState extends State<CareProviderField> {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.careProviderLabel,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Semantics(
          identifier: 'care_provider_use_typed_name',
          child: SwitchListTile(
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
        ),
        if (_useTyped)
          Semantics(
            identifier: 'care_provider_typed_name_field',
            child: TextField(
            controller: _typedController,
            decoration: InputDecoration(labelText: l.careProviderTypedName),
            onChanged: (v) =>
                widget.onChanged(contactId: null, typedName: v.trim()),
            ),
          )
        else if (widget.contactsLoading)
          const LinearProgressIndicator()
        else if (widget.contactsError)
          Text(l.careProviderContactsUnavailable)
        else
          Semantics(
            identifier: 'care_provider_dropdown',
            child: DropdownButtonFormField<String?>(
            initialValue: widget.contactId,
            decoration: InputDecoration(labelText: l.careProviderChooseContact),
            items: [
              DropdownMenuItem<String?>(value: null, child: Text(l.none)),
              ...widget.contacts.map(
                (c) =>
                    DropdownMenuItem<String?>(value: c.id, child: Text(c.name)),
              ),
            ],
            onChanged: (id) => widget.onChanged(contactId: id, typedName: null),
            ),
          ),
      ],
    );
  }
}
