import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../organization/presentation/providers/organization_providers.dart';
import '../../controllers/pet_form_controller.dart';

class PetOwnershipSelector extends ConsumerWidget {
  final PetFormController controller;
  final String? initialOrgId;
  const PetOwnershipSelector({required this.controller, this.initialOrgId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final orgsAsync = ref.watch(organizationListProvider);
    return orgsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (orgs) {
        if (orgs.isEmpty) return const SizedBox.shrink();
        // ...existing code for ownership selector UI, using controller.state
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.petOwnership,
                    style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold)),
                // ...rest of the UI, update controller state on selection
              ],
            ),
          ),
        );
      },
    );
  }
}
