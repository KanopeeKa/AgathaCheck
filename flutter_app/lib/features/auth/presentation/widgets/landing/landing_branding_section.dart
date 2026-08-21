import 'package:flutter/material.dart';

import '../../../../../core/theme/app_color_tokens.dart';
import '../../../../../l10n/app_localizations.dart';

/// Role-neutral story panel for the Guardian Operations Desk landing.
class LandingBrandingSection extends StatelessWidget {
  const LandingBrandingSection({
    super.key,
    required this.theme,
    required this.l10n,
  });

  final ThemeData theme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final text = theme.textTheme;

    return Semantics(
      container: true,
      label: l10n.landingDeskEyebrow,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 530),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/branding/agathatrack-care-mark.png',
                  width: 44,
                  height: 44,
                  excludeFromSemantics: true,
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.appTitle,
                  style: text.titleLarge?.copyWith(
                    color: AppColorTokens.operationsPaper,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 64),
            Text(
              l10n.landingDeskEyebrow.toUpperCase(),
              style: text.labelLarge?.copyWith(
                color: AppColorTokens.operationsGold,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(
                l10n.landingDeskHeadline,
                style: text.displaySmall?.copyWith(
                  color: AppColorTokens.operationsSurface,
                  fontWeight: FontWeight.w700,
                  height: 1.08,
                  letterSpacing: -1,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.landingDeskBody,
              style: text.titleMedium?.copyWith(
                color: AppColorTokens.operationsPaper.withValues(alpha: 0.84),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 36),
            const _DeskPromise(),
            const SizedBox(height: 36),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColorTokens.operationsOliveLight.withValues(
                  alpha: 0.72,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColorTokens.operationsGold.withValues(alpha: 0.36),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.home_outlined,
                    color: AppColorTokens.operationsGold,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.landingDeskCareNote,
                      style: text.bodyMedium?.copyWith(
                        color: AppColorTokens.operationsPaper,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeskPromise extends StatelessWidget {
  const _DeskPromise();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: AppColorTokens.operationsPaper,
      fontWeight: FontWeight.w600,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DeskPromiseRow(label: l10n.landingDeskPromiseAtAGlance, style: style),
        const SizedBox(height: 12),
        _DeskPromiseRow(label: l10n.landingDeskPromiseHandovers, style: style),
        const SizedBox(height: 12),
        _DeskPromiseRow(label: l10n.landingDeskPromisePrivate, style: style),
      ],
    );
  }
}

class _DeskPromiseRow extends StatelessWidget {
  const _DeskPromiseRow({required this.label, required this.style});

  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_outline,
          color: AppColorTokens.operationsGold,
          size: 20,
        ),
        const SizedBox(width: 10),
        Text(label, style: style),
      ],
    );
  }
}
