import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/care_safeguard.dart';
import '../providers/care_recommendations_provider.dart';
import 'cim_evidence_view.dart';

/// Calm info-blue safeguard card (Phase E).
class CareSafeguardCard extends ConsumerWidget {
  const CareSafeguardCard({
    super.key,
    required this.petId,
    required this.petName,
    required this.safeguard,
  });

  final String petId;
  final String petName;
  final CareSafeguard safeguard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    Future<void> dismiss() async {
      await ref
          .read(careIntelligenceRepositoryProvider)
          .dismissSafeguard(petId: petId, safeguardId: safeguard.id);
      ref.invalidate(petCareSafeguardsProvider(petId));
      ref.invalidate(petProfileCareSafeguardProvider(petId));
      ref.invalidate(petProfileCareSuggestionProvider(petId));
    }

    return Card(
      key: Key('care_safeguard_card_${safeguard.id}'),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.careSafeguardTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.careSafeguardWeightTrendDown(petName),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            CimEvidenceView(evidence: safeguard.evidence),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  key: Key('care_safeguard_view_changes_${safeguard.id}'),
                  onPressed: () => context.push('/pet/$petId/weight'),
                  child: Text(l.careSafeguardViewChanges),
                ),
                TextButton(
                  key: Key('care_safeguard_dismiss_${safeguard.id}'),
                  onPressed: dismiss,
                  child: Text(l.careSafeguardDismiss),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
