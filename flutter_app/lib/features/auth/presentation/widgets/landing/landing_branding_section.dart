import 'package:flutter/material.dart';

import '../../../../../core/theme/app_color_tokens.dart';
import '../../../../../l10n/app_localizations.dart';

/// Photo-led, role-neutral landing story. It deliberately carries product
/// context without asking a visitor to choose an experience before sign-in.
class LandingBrandingSection extends StatelessWidget {
  const LandingBrandingSection({
    super.key,
    required this.theme,
    required this.l10n,
    this.compact = false,
  });

  final ThemeData theme;
  final AppLocalizations l10n;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = theme.textTheme;
    final heroHeight = compact ? 350.0 : 500.0;

    return Semantics(
      container: true,
      label: l10n.landingDeskEyebrow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BrandLockup(text: text),
          const SizedBox(height: 26),
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: SizedBox(
                  height: heroHeight,
                  width: double.infinity,
                  child: Image.asset(
                    'assets/landing/care-pet-pair.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    semanticLabel: l10n.landingDeskEyebrow,
                  ),
                ),
              ),
              Positioned(
                right: compact ? 14 : 24,
                bottom: compact ? -22 : -30,
                child: _CareDeskPreview(
                  compact: compact,
                  l10n: l10n,
                  text: text,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 46 : 58),
          Text(
            l10n.landingDeskEyebrow.toUpperCase(),
            style: text.labelMedium?.copyWith(
              color: AppColorTokens.landingTealDeep,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 10),
          Semantics(
            header: true,
            child: Text(
              l10n.landingDeskHeadline,
              style: text.displaySmall?.copyWith(
                color: AppColorTokens.landingInk,
                fontWeight: FontWeight.w700,
                height: 1.04,
                letterSpacing: -1.1,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.landingDeskBody,
            style: text.titleMedium?.copyWith(
              color: AppColorTokens.landingInkSoft,
              height: 1.42,
            ),
          ),
          const SizedBox(height: 22),
          _CareNote(l10n: l10n, text: text),
        ],
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({required this.text});

  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 52,
          width: 52,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AppColorTokens.landingSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColorTokens.landingLine),
          ),
          child: Image.asset(
            'assets/branding/agathatrack-care-mark.png',
            excludeFromSemantics: true,
          ),
        ),
        const SizedBox(width: 12),
        RichText(
          text: TextSpan(
            style: text.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
            children: const [
              TextSpan(
                text: 'Agatha',
                style: TextStyle(color: AppColorTokens.guardianPrimary),
              ),
              TextSpan(
                text: 'Track',
                style: TextStyle(color: AppColorTokens.landingTealDeep),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CareDeskPreview extends StatelessWidget {
  const _CareDeskPreview({
    required this.compact,
    required this.l10n,
    required this.text,
  });

  final bool compact;
  final AppLocalizations l10n;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 218.0 : 260.0;
    return Semantics(
      container: true,
      label: l10n.landingDeskPromiseAtAGlance,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColorTokens.landingSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColorTokens.landingLine),
          boxShadow: const [
            BoxShadow(
              color: AppColorTokens.shadow,
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/branding/agathatrack-care-mark.png',
                  width: 25,
                  height: 25,
                  excludeFromSemantics: true,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.landingDeskPromiseAtAGlance,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelLarge?.copyWith(
                      color: AppColorTokens.landingInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _PreviewRow(
              icon: Icons.pets_outlined,
              label: l10n.landingDeskPromiseHandovers,
            ),
            const SizedBox(height: 8),
            _PreviewRow(
              icon: Icons.calendar_today_outlined,
              label: l10n.landingDeskPromisePrivate,
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 4,
          height: 26,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColorTokens.landingTeal,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 16, color: AppColorTokens.landingTealDeep),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColorTokens.landingInkSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _CareNote extends StatelessWidget {
  const _CareNote({required this.l10n, required this.text});

  final AppLocalizations l10n;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorTokens.landingTealSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColorTokens.landingLine),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.shield_outlined,
            color: AppColorTokens.landingTealDeep,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.landingDeskCareNote,
              style: text.bodyMedium?.copyWith(
                color: AppColorTokens.landingInk,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
