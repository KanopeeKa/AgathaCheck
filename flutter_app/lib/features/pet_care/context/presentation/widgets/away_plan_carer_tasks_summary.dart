import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../providers/care_context_providers.dart';

/// Carer workload summary for one pet during an absence (R-D3, simplified UI).
class AwayPlanCarerTasksSummary extends ConsumerWidget {
  const AwayPlanCarerTasksSummary({
    super.key,
    required this.absenceId,
    required this.petId,
  });

  final String absenceId;
  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(absenceCarePlanProvider(absenceId));
    return planAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (plan) {
        final petPlan = plan.pets.where((p) => p.petId == petId).firstOrNull;
        if (petPlan == null || petPlan.carerTasks.count <= 0) {
          return const SizedBox.shrink();
        }
        final l = AppLocalizations.of(context)!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            l.plannerCarerTasks(petPlan.carerTasks.count),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        );
      },
    );
  }
}
