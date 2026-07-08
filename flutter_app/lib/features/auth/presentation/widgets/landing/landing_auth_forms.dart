import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/web/native_login.dart';
import '../../providers/auth_providers.dart';
import 'landing_error_banner.dart';
import 'landing_logo.dart';

class LandingLoginForm extends StatefulWidget {
  const LandingLoginForm({
    super.key,
    required this.theme,
    required this.auth,
    required this.l10n,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.onSubmit,
    required this.onClearError,
    required this.nativeLogin,
    required this.onShowNativeLogin,
  });

  final ThemeData theme;
  final AuthState auth;
  final AppLocalizations l10n;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final Future<void> Function() onSubmit;
  final VoidCallback onClearError;
  final NativeLogin nativeLogin;
  final VoidCallback onShowNativeLogin;

  @override
  State<LandingLoginForm> createState() => _LandingLoginFormState();
}

class _LandingLoginFormState extends State<LandingLoginForm> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Form(
        key: widget.formKey,
        child: Column(
          children: [
            TextFormField(
              key: const Key('login_email_field'),
              controller: widget.emailController,
              decoration: InputDecoration(
                labelText: widget.l10n.email,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email,
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return widget.l10n.emailRequired;
                }
                if (!v.contains('@')) return widget.l10n.enterValidEmail;
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('login_password_field'),
              controller: widget.passwordController,
              decoration: InputDecoration(
                labelText: widget.l10n.password,
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  tooltip: _obscure
                      ? widget.l10n.showPassword
                      : widget.l10n.hidePassword,
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              obscureText: _obscure,
              autofillHints: const [AutofillHints.password],
              validator: (v) {
                if (v == null || v.isEmpty) return widget.l10n.passwordRequired;
                return null;
              },
              onFieldSubmitted: (_) => widget.onSubmit(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const Key('forgot_password_link'),
                onPressed: () => context.go('/forgot-password'),
                child: Text(
                  widget.l10n.forgotPassword,
                  style: widget.theme.textTheme.bodySmall?.copyWith(
                    color: widget.theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            LandingErrorBanner(theme: widget.theme, auth: widget.auth),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('login_submit_button'),
                onPressed: widget.auth.isLoading ? null : widget.onSubmit,
                child: widget.auth.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.l10n.signIn),
              ),
            ),
            if (kIsWeb && widget.nativeLogin.isAvailable)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  key: const Key('native_login_button'),
                  onPressed: widget.auth.isLoading
                      ? null
                      : widget.onShowNativeLogin,
                  icon: const Icon(Icons.password_outlined, size: 18),
                  label: Text(widget.l10n.signInWithPasswordManager),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class LandingSignupForm extends StatefulWidget {
  const LandingSignupForm({
    super.key,
    required this.theme,
    required this.auth,
    required this.l10n,
    required this.formKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmController,
    required this.onSubmit,
  });

  final ThemeData theme;
  final AuthState auth;
  final AppLocalizations l10n;
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final Future<void> Function() onSubmit;

  @override
  State<LandingSignupForm> createState() => _LandingSignupFormState();
}

class _LandingSignupFormState extends State<LandingSignupForm> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Form(
        key: widget.formKey,
        child: Column(
          children: [
            TextFormField(
              key: const Key('signup_first_name_field'),
              controller: widget.firstNameController,
              decoration: InputDecoration(
                labelText: widget.l10n.firstName,
                prefixIcon: const Icon(Icons.person_outlined),
              ),
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.givenName],
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('signup_last_name_field'),
              controller: widget.lastNameController,
              decoration: InputDecoration(
                labelText: widget.l10n.lastName,
                prefixIcon: const Icon(Icons.person_outlined),
              ),
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.familyName],
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('signup_email_field'),
              controller: widget.emailController,
              decoration: InputDecoration(
                labelText: widget.l10n.email,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return widget.l10n.emailRequired;
                }
                if (!v.contains('@')) return widget.l10n.enterValidEmail;
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('signup_password_field'),
              controller: widget.passwordController,
              decoration: InputDecoration(
                labelText: widget.l10n.password,
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  tooltip: _obscure
                      ? widget.l10n.showPassword
                      : widget.l10n.hidePassword,
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              obscureText: _obscure,
              autofillHints: const [AutofillHints.newPassword],
              validator: (v) {
                if (v == null || v.isEmpty) return widget.l10n.passwordRequired;
                if (v.length < 6) return widget.l10n.atLeast6Characters;
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('signup_confirm_password_field'),
              controller: widget.confirmController,
              decoration: InputDecoration(
                labelText: widget.l10n.confirmPassword,
                prefixIcon: const Icon(Icons.lock_outlined),
              ),
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              validator: (v) {
                if (v != widget.passwordController.text) {
                  return widget.l10n.passwordsDoNotMatch;
                }
                return null;
              },
              onFieldSubmitted: (_) => widget.onSubmit(),
            ),
            LandingErrorBanner(theme: widget.theme, auth: widget.auth),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('signup_submit_button'),
                onPressed: widget.auth.isLoading ? null : widget.onSubmit,
                child: widget.auth.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.l10n.createAccount),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: buildLandingLogo(theme, size: 64),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.appTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            TabBar(
              controller: tabController,
              tabs: [
                Tab(text: l10n.signIn),
                Tab(text: l10n.createAccount),
              ],
              onTap: (_) => onTabTap(),
            ),
            const SizedBox(height: 24),
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
