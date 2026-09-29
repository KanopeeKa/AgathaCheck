import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/people_providers.dart';

/// Resolves a legacy `vets` id to a People contact route.
class PeopleLegacyVetRedirectScreen extends ConsumerStatefulWidget {
  const PeopleLegacyVetRedirectScreen({
    super.key,
    required this.vetId,
    this.edit = false,
  });

  final String vetId;
  final bool edit;

  @override
  ConsumerState<PeopleLegacyVetRedirectScreen> createState() =>
      _PeopleLegacyVetRedirectScreenState();
}

class _PeopleLegacyVetRedirectScreenState
    extends ConsumerState<PeopleLegacyVetRedirectScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirect());
  }

  Future<void> _redirect() async {
    await ref.read(peopleContactsProvider.notifier).refresh();
    if (!mounted) return;
    final contactId = ref
        .read(peopleContactsProvider.notifier)
        .findByLegacyVetId(widget.vetId)
        ?.id;
    if (contactId != null && mounted) {
      final path = widget.edit
          ? '/pc/people/$contactId/edit'
          : '/pc/people/$contactId';
      context.go(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final contactId = ref.watch(
      peopleContactIdForLegacyVetProvider(widget.vetId),
    );
    if (contactId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final path = widget.edit
            ? '/pc/people/$contactId/edit'
            : '/pc/people/$contactId';
        context.go(path);
      });
    }
    return Scaffold(
      body: Center(
        child: contactId == null
            ? Text(l.peopleDetailNotFound)
            : const CircularProgressIndicator(),
      ),
    );
  }
}
