import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../providers/org_discovery_provider.dart';

/// Debounced name search for the Discover screen (D-v3-DISC-1).
class OrgDiscoverSearchField extends ConsumerStatefulWidget {
  const OrgDiscoverSearchField({super.key});

  @override
  ConsumerState<OrgDiscoverSearchField> createState() =>
      _OrgDiscoverSearchFieldState();
}

class _OrgDiscoverSearchFieldState
    extends ConsumerState<OrgDiscoverSearchField> {
  static const _debounceMs = 300;

  late final TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: _debounceMs), () {
      ref.read(orgDiscoverySearchQueryProvider.notifier).state = value.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Semantics(
      identifier: 'org_discover_search_field',
      textField: true,
      label: l.orgDiscoverySearchPlaceholder,
      child: TextField(
        key: const Key('org_discover_search_field'),
        controller: _controller,
        decoration: InputDecoration(
          hintText: l.orgDiscoverySearchPlaceholder,
          prefixIcon: const Icon(Icons.search),
          isDense: true,
        ),
        textInputAction: TextInputAction.search,
        onChanged: _onChanged,
      ),
    );
  }
}
