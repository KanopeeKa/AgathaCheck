import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/care_intelligence_exception.dart';
import '../../domain/entities/care_safeguard.dart';
import '../providers/care_recommendations_provider.dart';
import '../../../pet_care/presentation/providers/pet_care_presentation_providers.dart';
import 'cim_evidence_view.dart';

/// Calm info-blue safeguard card (Phase E).
class CareSafeguardCard extends ConsumerStatefulWidget {
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
  ConsumerState<CareSafeguardCard> createState() => _CareSafeguardCardState();
}

class _CareSafeguardCardState extends ConsumerState<CareSafeguardCard> {
  bool _dismissing = false;

  Future<void> _dismiss() async {
    if (_dismissing) return;
    setState(() => _dismissing = true);
    try {
      await ref
          .read(careIntelligenceRepositoryProvider)
          .dismissSafeguard(
            petId: widget.petId,
            safeguardId: widget.safeguard.id,
          );
      ref.invalidate(petCareSafeguardsProvider(widget.petId));
      ref.invalidate(petProfileCareSafeguardProvider(widget.petId));
      ref.invalidate(petProfileCareSuggestionProvider(widget.petId));
      ref.invalidate(petProfileCareMilestoneProvider(widget.petId));
    } catch (error) {
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      final message = (error is CareIntelligenceException && error.isForbidden)
          ? l.careSuggestionEditForbidden
          : l.careSafeguardDismissFailed;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _dismissing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final safeguard = widget.safeguard;

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
              l.careSafeguardWeightTrendDown(widget.petName),
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
                  onPressed: () => context.push('/pet/${widget.petId}/weight'),
                  child: Text(l.careSafeguardViewChanges),
                ),
                TextButton(
                  key: Key('care_safeguard_dismiss_${safeguard.id}'),
                  onPressed: _dismissing ? null : _dismiss,
                  child: _dismissing
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l.careSafeguardDismiss),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
