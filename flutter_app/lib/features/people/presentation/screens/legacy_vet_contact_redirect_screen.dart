import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/people_providers.dart';

/// Resolves a legacy `vets` table id via People API, then opens the contact.
class LegacyVetContactRedirectScreen extends ConsumerStatefulWidget {
  const LegacyVetContactRedirectScreen({
    super.key,
    required this.vetId,
    this.edit = false,
  });

  final String vetId;
  final bool edit;

  @override
  ConsumerState<LegacyVetContactRedirectScreen> createState() =>
      _LegacyVetContactRedirectScreenState();
}

class _LegacyVetContactRedirectScreenState
    extends ConsumerState<LegacyVetContactRedirectScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirect());
  }

  Future<void> _redirect() async {
    final contactId = await ref.read(
      legacyVetContactIdProvider(widget.vetId).future,
    );
    if (!mounted) return;
    if (contactId != null) {
      final path = widget.edit
          ? '/pc/people/$contactId/edit'
          : '/pc/people/$contactId';
      context.go(path);
    } else {
      context.go('/pc/people?filter=professionals');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(legacyVetContactIdProvider(widget.vetId));
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
