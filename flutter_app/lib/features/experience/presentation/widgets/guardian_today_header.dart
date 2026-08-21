import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../health_tracking/domain/entities/health_entry.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../screens/guardian/guardian_dashboard_helpers.dart';

/// Compact orientation layer for the Guardian dashboard. This is deliberately
/// not a [DashboardSection]: the only management domains remain pets, care, and
/// vets.
class GuardianTodayHeader extends StatelessWidget {
  const GuardianTodayHeader({
    super.key,
    required this.entriesAsync,
    required this.pets,
    required this.onRetry,
  });

  final AsyncValue<List<HealthEntry>> entriesAsync;
  final List<Pet> pets;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      header: true,
      label: l.today,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: entriesAsync.when(
            loading: () => Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(l.today, style: theme.textTheme.titleLarge),
              ],
            ),
            error: (_, __) => Row(
              children: [
                const Icon(Icons.error_outline),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l.todayLoadError,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                TextButton(onPressed: onRetry, child: Text(l.retry)),
              ],
            ),
            data: (entries) {
              final summary = GuardianTodayCareSummary.forPets(
                entries: entries,
                pets: pets,
              );
              final detail = _detail(l, summary);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.today, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _detail(AppLocalizations l, GuardianTodayCareSummary summary) {
    if (!summary.hasAttention) return l.todayAllClear;
    return l.todayAttentionSummary(summary.overdueCount, summary.dueTodayCount);
  }
}
