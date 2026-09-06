import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../screens/pet_care/pet_care_dashboard_helpers.dart';

/// Compact, provider-free orientation layer for the Guardian dashboard.
///
/// It consumes the foundation's state and summary rather than selecting care,
/// pets, or async state itself. It intentionally contains no management rows
/// and is not a dashboard section or navigation destination.
class PetCareTodayOrientation extends StatelessWidget {
  const PetCareTodayOrientation({
    super.key,
    required this.state,
    this.summary,
    this.onRetry,
  });

  final PetCareTodayScreenState state;
  final PetCareTodayCareSummary? summary;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final resolvedState = _resolvedState;
    final semanticLabel = _semanticLabel(l, resolvedState);

    return Semantics(
      key: const Key('pet_care_today_orientation'),
      container: true,
      header: true,
      label: semanticLabel,
      explicitChildNodes: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          border: Border.all(
            color: AppColorTokens.operationsOlive.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            key: Key('pet_care_today_orientation_${resolvedState.name}'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Text(l.today, style: theme.textTheme.titleLarge),
              ),
              const SizedBox(height: 8),
              _body(context, l, resolvedState),
            ],
          ),
        ),
      ),
    );
  }

  PetCareTodayScreenState get _resolvedState {
    final summaryRequired =
        state == PetCareTodayScreenState.attention ||
        state == PetCareTodayScreenState.allClear;
    return summaryRequired && summary == null
        ? PetCareTodayScreenState.partial
        : state;
  }

  String _semanticLabel(AppLocalizations l, PetCareTodayScreenState state) {
    switch (state) {
      case PetCareTodayScreenState.attention:
        return _attentionLabel(l);
      case PetCareTodayScreenState.allClear:
        return '${l.today}: ${l.todayAllClear}';
      case PetCareTodayScreenState.firstUse:
        return '${l.today}: ${l.guardianOnboardingWelcomeBody}';
      case PetCareTodayScreenState.loading:
        return l.today;
      case PetCareTodayScreenState.partial:
        return '${l.today}: ${l.careLoadError}';
      case PetCareTodayScreenState.error:
        return '${l.today}: ${l.todayLoadError}';
    }
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l,
    PetCareTodayScreenState state,
  ) {
    final theme = Theme.of(context);
    switch (state) {
      case PetCareTodayScreenState.attention:
        return _attentionBody(context, l);
      case PetCareTodayScreenState.allClear:
        return _statusLine(
          icon: Icons.check_circle_outline,
          message: l.todayAllClear,
          color: AppColorTokens.petCareCareActive,
        );
      case PetCareTodayScreenState.firstUse:
        return _statusLine(
          icon: Icons.pets_outlined,
          message: l.guardianOnboardingWelcomeBody,
          color: theme.colorScheme.onPrimaryContainer,
        );
      case PetCareTodayScreenState.loading:
        return const ExcludeSemantics(
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case PetCareTodayScreenState.partial:
        return _statusLine(
          icon: Icons.info_outline,
          message: l.careLoadError,
          color: theme.colorScheme.onPrimaryContainer,
        );
      case PetCareTodayScreenState.error:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline, color: theme.colorScheme.error),
                const SizedBox(width: 10),
                Expanded(
                  child: ExcludeSemantics(
                    child: Text(
                      l.todayLoadError,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ),
              ],
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Semantics(
                  button: true,
                  label: l.retry,
                  child: TextButton(
                    onPressed: onRetry,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: ExcludeSemantics(child: Text(l.retry)),
                  ),
                ),
              ),
            ],
          ],
        );
    }
  }

  Widget _attentionBody(BuildContext context, AppLocalizations l) {
    final theme = Theme.of(context);
    final values = summary!;

    return LayoutBuilder(
      builder: (context, constraints) => ExcludeSemantics(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _countPill(
              maxWidth: constraints.maxWidth,
              icon: Icons.priority_high_outlined,
              label: l.todayOverdueCount(values.overdueCount),
              color: theme.colorScheme.error,
            ),
            _countPill(
              maxWidth: constraints.maxWidth,
              icon: Icons.today_outlined,
              label: l.todayDueCount(values.dueTodayCount),
              color: AppColorTokens.operationsOlive,
            ),
            _countPill(
              maxWidth: constraints.maxWidth,
              icon: Icons.schedule_outlined,
              label: '${values.upcomingCount} ${l.careStatusUpcoming}',
              color: AppColorTokens.petCareCareActive,
            ),
          ],
        ),
      ),
    );
  }

  String _attentionLabel(AppLocalizations l) {
    final values = summary!;
    return '${l.today}: ${l.todayOverdueCount(values.overdueCount)}. '
        '${l.todayDueCount(values.dueTodayCount)}. '
        '${values.upcomingCount} ${l.careStatusUpcoming}.';
  }

  Widget _statusLine({
    required IconData icon,
    required String message,
    required Color color,
  }) {
    return ExcludeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }

  Widget _countPill({
    required double maxWidth,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Flexible(child: Text(label)),
          ],
        ),
      ),
    );
  }
}
