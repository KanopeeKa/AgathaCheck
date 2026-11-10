import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/async_state/async_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/people_providers.dart';

/// Resolves a legacy `vets` table id via People API, then opens the contact.
class LegacyVetContactRedirectScreen extends ConsumerWidget {
  const LegacyVetContactRedirectScreen({
    super.key,
    required this.vetId,
    this.edit = false,
  });

  final String vetId;
  final bool edit;

  void _goToContact(BuildContext context, String contactId) {
    final path = edit ? '/pc/people/$contactId/edit' : '/pc/people/$contactId';
    context.go(path);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mappingAsync = ref.watch(legacyVetContactIdProvider(vetId));

    ref.listen(legacyVetContactIdProvider(vetId), (previous, next) {
      next.whenOrNull(
        data: (contactId) {
          if (!context.mounted) return;
          if (contactId != null) {
            _goToContact(context, contactId);
          } else {
            context.go('/pc/people?filter=professionals');
          }
        },
      );
    });

    return mappingAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) {
        final l = AppLocalizations.of(context)!;
        return Scaffold(
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AsyncErrorState(
                title: l.peopleListLoadError,
                onRetry: () => ref.invalidate(legacyVetContactIdProvider(vetId)),
                retryKey: const Key('legacy_vet_redirect_retry'),
              ),
              TextButton(
                key: const Key('legacy_vet_back_to_contacts'),
                onPressed: () => context.go('/pc/people'),
                child: Text(l.peopleBackToContacts),
              ),
            ],
          ),
        );
      },
      data: (_) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
