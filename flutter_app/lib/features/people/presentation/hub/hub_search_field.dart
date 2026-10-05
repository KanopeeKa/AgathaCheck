import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class HubSearchField extends StatefulWidget {
  const HubSearchField({
    super.key,
    required this.query,
    required this.onQueryChanged,
  });

  final String query;
  final ValueChanged<String> onQueryChanged;

  @override
  State<HubSearchField> createState() => _HubSearchFieldState();
}

class _HubSearchFieldState extends State<HubSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant HubSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query && _controller.text != widget.query) {
      _controller.text = widget.query;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Semantics(
      label: l.peopleHubSearchHint,
      child: TextField(
        key: const Key('people_list_search'),
        controller: _controller,
        decoration: InputDecoration(
          hintText: l.peopleHubSearchHint,
          prefixIcon: const Icon(Icons.search),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: widget.onQueryChanged,
      ),
    );
  }
}
