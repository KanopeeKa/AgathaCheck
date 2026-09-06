import 'package:flutter/material.dart';

import '../../../../../core/theme/app_color_tokens.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../about/presentation/widgets/legal_footer_links.dart';
import 'landing_branding_section.dart';

/// Responsive public-auth composition. Authentication state is intentionally
/// supplied by [authCard] so presentation never changes the login contract.
class LandingOperationsDeskPage extends StatelessWidget {
  const LandingOperationsDeskPage({
    super.key,
    required this.baseTheme,
    required this.l10n,
    required this.authCard,
  });

  final ThemeData baseTheme;
  final AppLocalizations l10n;
  final Widget authCard;

  @override
  Widget build(BuildContext context) {
    final landingTheme = _landingTheme(baseTheme);

    return Theme(
      data: landingTheme,
      child: Scaffold(
        backgroundColor: AppColorTokens.landingCanvas,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 920;
              final authSurface = _AuthSurface(
                authCard: authCard,
                compact: !isWide,
              );
              final storySurface = _StorySurface(l10n: l10n, compact: !isWide);

              if (isWide) {
                return Row(
                  children: [
                    Expanded(flex: 9, child: authSurface),
                    Expanded(flex: 11, child: storySurface),
                  ],
                );
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [authSurface, storySurface],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  ThemeData _landingTheme(ThemeData theme) {
    final scheme = theme.colorScheme.copyWith(
      primary: AppColorTokens.petCarePrimary,
      onPrimary: AppColorTokens.inverse,
      primaryContainer: AppColorTokens.guardianLight,
      onPrimaryContainer: AppColorTokens.guardianActive,
      secondary: AppColorTokens.landingTeal,
      onSecondary: AppColorTokens.inverse,
      secondaryContainer: AppColorTokens.landingTealSoft,
      onSecondaryContainer: AppColorTokens.landingTealDeep,
      surface: AppColorTokens.landingSurface,
      onSurface: AppColorTokens.landingInk,
      surfaceContainerHighest: AppColorTokens.landingCanvas,
      outline: AppColorTokens.landingLine,
      outlineVariant: AppColorTokens.landingLine,
    );

    return theme.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColorTokens.landingCanvas,
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: AppColorTokens.landingInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorTokens.landingLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorTokens.landingLine),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColorTokens.landingFocus, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColorTokens.petCarePrimary,
          foregroundColor: AppColorTokens.inverse,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorTokens.petCarePrimary,
          minimumSize: const Size(48, 48),
        ),
      ),
    );
  }
}

class _StorySurface extends StatelessWidget {
  const _StorySurface({required this.l10n, required this.compact});

  final AppLocalizations l10n;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final content = ColoredBox(
      color: AppColorTokens.landingCanvas,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 20 : 48,
          vertical: compact ? 28 : 44,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: LandingBrandingSection(
              theme: Theme.of(context),
              l10n: l10n,
              compact: compact,
            ),
          ),
        ),
      ),
    );

    // Desktop panes have independent scroll areas so the photo-led story never
    // overflows a short browser viewport. On narrow layouts, the parent owns
    // the single vertical scroll position.
    return compact ? content : SingleChildScrollView(child: content);
  }
}

class _AuthSurface extends StatelessWidget {
  const _AuthSurface({required this.authCard, required this.compact});

  final Widget authCard;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 470),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            authCard,
            const SizedBox(height: 18),
            const Center(child: LegalFooterLinks()),
          ],
        ),
      ),
    );

    return ColoredBox(
      color: AppColorTokens.landingCanvas,
      child: Center(
        // Narrow layouts use the outer page scroll view. Keeping this content
        // non-scrollable avoids nesting vertical scroll views with unbounded
        // constraints. Desktop retains an independently scrollable auth pane.
        child: compact ? content : SingleChildScrollView(child: content),
      ),
    );
  }
}
