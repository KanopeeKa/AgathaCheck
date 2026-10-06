import 'package:flutter/material.dart';

import '../../../../../core/branding/logo_assets.dart';
import '../../../../../core/theme/app_color_tokens.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../providers/auth_providers.dart';

class LandingAuthCard extends StatelessWidget {
  const LandingAuthCard({
    super.key,
    required this.theme,
    required this.auth,
    required this.l10n,
    required this.tabController,
    required this.onTabTap,
    required this.loginForm,
    required this.signupForm,
  });

  final ThemeData theme;
  final AuthState auth;
  final AppLocalizations l10n;
  final TabController tabController;
  final VoidCallback onTabTap;
  final Widget loginForm;
  final Widget signupForm;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColorTokens.landingSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: AppColorTokens.landingLine),
      ),
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColorTokens.landingTealSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    LogoAssets.careMarkPng(),
                    excludeFromSemantics: true,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.appTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColorTokens.landingInk,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            AnimatedBuilder(
              animation: tabController,
              builder: (context, _) {
                final isSignIn = tabController.index == 0;
                return Semantics(
                  header: true,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      isSignIn
                          ? l10n.landingDeskWelcomeBack
                          : l10n.landingDeskCreateHeading,
                      key: ValueKey(isSignIn),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColorTokens.landingInk,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: tabController,
              builder: (context, _) {
                final isSignIn = tabController.index == 0;
                return Text(
                  isSignIn
                      ? l10n.landingDeskWelcomeBackBody
                      : l10n.landingDeskCreateBody,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColorTokens.landingInkSoft,
                    height: 1.4,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: AppColorTokens.landingLine),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(
                    color: AppColorTokens.petCarePrimary,
                    width: 3,
                  ),
                  insets: EdgeInsets.symmetric(horizontal: 18),
                ),
                labelColor: AppColorTokens.petCarePrimary,
                unselectedLabelColor: AppColorTokens.landingInkSoft,
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: l10n.signIn),
                  Tab(text: l10n.createAccount),
                ],
                onTap: (_) => onTabTap(),
              ),
            ),
            const SizedBox(height: 26),
            AnimatedBuilder(
              animation: tabController,
              builder: (context, _) {
                if (tabController.index == 0) {
                  return loginForm;
                } else {
                  return signupForm;
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
