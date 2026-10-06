import 'package:flutter/material.dart';
import 'package:pet_profile_app/core/theme/app_color_tokens.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

/// Presentational first-use cookie consent banner surface.
class ConsentBannerSurface extends StatelessWidget {
  const ConsentBannerSurface({
    super.key,
    required this.l10n,
    required this.theme,
    required this.onManagePreferences,
    required this.onAcceptAll,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final VoidCallback onManagePreferences;
  final VoidCallback onAcceptAll;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      child: Material(
        color: AppColorTokens.operationsSurface,
        elevation: 6,
        shadowColor: AppColorTokens.operationsOlive.withValues(alpha: 0.28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppColorTokens.operationsOlive.withValues(alpha: 0.2),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.cookie_outlined,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        l10n.consentBannerTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColorTokens.operationsInk,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.consentBannerMessage,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColorTokens.body,
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final actions = [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onManagePreferences,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColorTokens.operationsOlive,
                          side: const BorderSide(
                            color: AppColorTokens.operationsOlive,
                          ),
                        ),
                        child: Text(l10n.consentManagePreferences),
                      ),
                    ),
                    Expanded(
                      child: FilledButton(
                        onPressed: onAcceptAll,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColorTokens.operationsOlive,
                          foregroundColor: AppColorTokens.inverse,
                        ),
                        child: Text(l10n.consentAcceptAll),
                      ),
                    ),
                  ];

                  if (constraints.maxWidth < 400) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        actions[0],
                        const SizedBox(height: 12),
                        actions[1],
                      ],
                    );
                  }

                  return Row(
                    children: [
                      actions[0],
                      const SizedBox(width: 12),
                      actions[1],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
