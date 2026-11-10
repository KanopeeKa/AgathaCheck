import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Error state for a failed primary load (design system § 6.10, review rule X-1).
///
/// Shows calm, localized copy and a Retry action. It never takes an exception or backend message:
/// callers pass a localized [title] naming what failed ("We couldn't load your pets") and log the
/// exception themselves. Place it inside the screen's shell so title, back and bell stay visible.
class AsyncErrorState extends StatelessWidget {
  const AsyncErrorState({
    super.key,
    this.title,
    this.detail,
    this.onRetry,
    this.retryKey,
  });

  /// Localized title. Defaults to `loadErrorTitle` ("We couldn't load this").
  final String? title;

  /// Localized one-line hint. Defaults to `loadErrorRetryHint`.
  final String? detail;

  /// Re-runs the failed load. When null, no Retry button is shown (for example a gone record).
  final VoidCallback? onRetry;

  /// Optional key for the Retry button (E2E and widget tests).
  final Key? retryKey;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Icon(Icons.error_outline, size: 32, color: scheme.error),
              ),
              const SizedBox(height: 12),
              Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  title ?? l.loadErrorTitle,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                detail ?? l.loadErrorRetryHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  key: retryKey,
                  onPressed: onRetry,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(l.retry),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
