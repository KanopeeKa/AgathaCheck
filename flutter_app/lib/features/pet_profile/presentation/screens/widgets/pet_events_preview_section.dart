import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/dashboard_section.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../domain/entities/pet.dart';

/// Pet detail events preview with link to the manage-events screen.
class PetEventsPreviewSection extends ConsumerWidget {
  const PetEventsPreviewSection({
    super.key,
    required this.petId,
    required this.pet,
  });

  final String petId;
  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final healthAsync = ref.watch(petHealthEventsByIdProvider(petId));
    final otherAsync = ref.watch(petOtherEventsByIdProvider(petId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DashboardSection(
        title: l.manageEvents,
        previewBuilder: (ctx) {
          final healthCount = healthAsync.valueOrNull?.length ?? 0;
          final otherCount = otherAsync.valueOrNull?.length ?? 0;
          final total = healthCount + otherCount;

          if (healthAsync.isLoading || otherAsync.isLoading) {
            return const SizedBox(
              height: 24,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }

          if (total == 0) {
            return Text(
              l.noEventsYet,
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              ),
            );
          }

          return Text(
            l.petEventsSummary(total),
            style: Theme.of(ctx).textTheme.bodyMedium,
          );
        },
        endLink: DashboardSectionLink(
          label: l.manageEvents,
          onPressed: () => context.go('/pet/$petId/events'),
        ),
      ),
    );
  }
}
