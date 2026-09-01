import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../organization/presentation/utils/foster_placement_display.dart';
import '../providers/foster_pet_session_providers.dart';

class PetFosteringSessionSummaryCard extends ConsumerWidget {
  const PetFosteringSessionSummaryCard({
    super.key,
    required this.petId,
    this.placementId,
  });

  final String petId;
  final String? placementId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final placementAsync = ref.watch(
      openFosterPlacementForPetStateProvider(petId),
    );

    return placementAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (placement) {
        if (placement == null) return const SizedBox.shrink();

        final resolvedPlacementId = placementId ?? placement.id;
        final orgLabel = placement.organizationName.isNotEmpty
            ? placement.organizationName
            : l.organizations;
        final statusLabel = placement.sessionStatus.isNotEmpty
            ? fosterSessionStatusLabel(l, placement.sessionStatus)
            : l.fosterPlacementInProgress;

        return Card(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.fosteringSessionDetailTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(statusLabel, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  l.fosterPlacementInviteFrom(orgLabel),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    key: const Key('view_fostering_session_button'),
                    onPressed: () => context.push(
                      '/pet/$petId/fostering-session?placementId=$resolvedPlacementId',
                    ),
                    icon: const Icon(Icons.open_in_new),
                    label: Text(l.fosteringSessionManage),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
