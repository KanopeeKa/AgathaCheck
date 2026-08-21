import 'package:flutter/material.dart';

import '../../../../../core/theme/app_color_tokens.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../about/presentation/widgets/legal_footer_links.dart';
import 'landing_branding_section.dart';

/// Responsive two-surface landing composition for the public auth entry point.
///
/// Auth fields and authentication behavior remain supplied by [authCard]. This
/// widget only owns the role-neutral Operations Desk presentation.
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
    final deskTheme = _operationsDeskTheme(baseTheme);

    return Theme(
      data: deskTheme,
      child: Scaffold(
        backgroundColor: AppColorTokens.operationsPaper,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 920;
              if (isWide) {
                return SizedBox(
                  height: constraints.maxHeight,
                  child: Row(
                    children: [
                      Expanded(flex: 11, child: _StorySurface(l10n: l10n)),
                      Expanded(
                        flex: 9,
                        child: _AuthSurface(authCard: authCard),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StorySurface(l10n: l10n, compact: true),
                    _AuthSurface(authCard: authCard, compact: true),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  ThemeData _operationsDeskTheme(ThemeData theme) {
    final scheme = theme.colorScheme.copyWith(
      primary: AppColorTokens.operationsOliveLight,
      onPrimary: AppColorTokens.operationsSurface,
      primaryContainer: AppColorTokens.operationsPaper,
      onPrimaryContainer: AppColorTokens.operationsInk,
      secondary: AppColorTokens.operationsGold,
      onSecondary: AppColorTokens.operationsInk,
      surface: AppColorTokens.operationsSurface,
      onSurface: AppColorTokens.operationsInk,
      surfaceContainerHighest: AppColorTokens.operationsPaper,
      outline: AppColorTokens.operationsOlive.withValues(alpha: 0.38),
      outlineVariant: AppColorTokens.operationsOlive.withValues(alpha: 0.18),
    );

    return theme.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColorTokens.operationsPaper,
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: AppColorTokens.operationsSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(
            color: AppColorTokens.operationsOliveLight,
            width: 2,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColorTokens.operationsOliveLight,
          foregroundColor: AppColorTokens.operationsSurface,
          minimumSize: const Size.fromHeight(50),
          shape: const StadiumBorder(),
          textStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorTokens.operationsOliveLight,
          minimumSize: const Size(48, 48),
        ),
      ),
    );
  }
}

class _StorySurface extends StatelessWidget {
  const _StorySurface({required this.l10n, this.compact = false});

  final AppLocalizations l10n;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColorTokens.operationsOlive,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 28 : 64,
          vertical: compact ? 36 : 52,
        ),
        child: Align(
          alignment: compact ? Alignment.centerLeft : Alignment.center,
          child: LandingBrandingSection(theme: Theme.of(context), l10n: l10n),
        ),
      ),
    );
  }
}

class _AuthSurface extends StatelessWidget {
  const _AuthSurface({required this.authCard, this.compact = false});

  final Widget authCard;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColorTokens.operationsPaper,
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 20 : 44,
            vertical: compact ? 32 : 40,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                authCard,
                const SizedBox(height: 18),
                const Center(child: LegalFooterLinks()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
