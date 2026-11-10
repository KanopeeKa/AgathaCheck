import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'labelled_progress.dart';

/// State of a supplemental (dependent) query shown next to the content it decorates.
enum SupplementalState {
  /// The query has not resolved yet.
  loading,

  /// The query failed; the content is shown without it.
  unavailable,
}

/// One-line caption for a supplemental query that is loading or failed (review rule X-2).
///
/// Use it next to content that would otherwise look like "none" or "all set" when a dependent
/// query has not resolved: tag filters, care status on tiles, pet names on a plan card. [label]
/// is localized and names what is missing ("Tag filters unavailable"). When [onRetry] is set
/// and the state is [SupplementalState.unavailable], a Retry action is shown.
class SupplementalStateCaption extends StatelessWidget {
  const SupplementalStateCaption({
    super.key,
    required this.state,
    required this.label,
    this.onRetry,
    this.retryKey,
  });

  final SupplementalState state;

  /// Localized text naming the missing information.
  final String label;

  /// Re-runs the supplemental query; only used when [state] is unavailable.
  final VoidCallback? onRetry;

  /// Optional key for the Retry button (E2E and widget tests).
  final Key? retryKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final showRetry = state == SupplementalState.unavailable && onRetry != null;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          if (state == SupplementalState.loading)
            LabelledProgress(label: label, centered: false, size: 16)
          else
            ExcludeSemantics(
              child: Icon(
                Icons.info_outline,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          // While loading, LabelledProgress already exposes [label]; keep the visible text out of
          // semantics so screen readers announce it once.
          if (state == SupplementalState.loading)
            ExcludeSemantics(child: Text(label, style: muted))
          else
            Text(label, style: muted),
          if (showRetry)
            TextButton(
              key: retryKey,
              onPressed: onRetry,
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(AppLocalizations.of(context)!.retry),
            ),
        ],
      ),
    );
  }
}
