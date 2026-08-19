import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/web/native_login.dart';
import '../../../../../core/web/native_login_inline_view.dart';
import '../../providers/auth_providers.dart';
import 'landing_error_banner.dart';

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
    required this.onNativeLogin,
    required this.onNativeForgot,
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
  final Future<void> Function(String email, String password) onNativeLogin;
  final VoidCallback onNativeForgot;

  @override
  State<LandingLoginForm> createState() => _LandingLoginFormState();
}

class _LandingLoginFormState extends State<LandingLoginForm> {
  bool _obscure = true;

  void _attachNativeLogin() {
    widget.nativeLogin.attachInline(
      emailLabel: widget.l10n.email,
      passwordLabel: widget.l10n.password,
      signInLabel: widget.l10n.signIn,
      forgotLabel: widget.l10n.forgotPassword,
      onSubmit: (email, password) => widget.onNativeLogin(email, password),
      onForgot: widget.onNativeForgot,
    );
    _syncNativeLoginState();
  }

  void _syncNativeLoginState() {
    widget.nativeLogin.setBusy(widget.auth.isLoading);
    widget.nativeLogin.setError(widget.auth.error ?? '');
  }

  @override
  void initState() {
    super.initState();
    if (kIsWeb && widget.nativeLogin.isAvailable) {
      _attachNativeLogin();
    }
  }

  @override
  void didUpdateWidget(covariant LandingLoginForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!kIsWeb || !widget.nativeLogin.isAvailable) return;

    _attachNativeLogin();
  }

  @override
  void dispose() {
    if (kIsWeb && widget.nativeLogin.isAvailable) {
      widget.nativeLogin.detach();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && widget.nativeLogin.isAvailable) {
      return const NativeLoginInlineView();
    }

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
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

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
                  tooltip: _obscurePassword
                      ? widget.l10n.showPassword
                      : widget.l10n.hidePassword,
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              obscureText: _obscurePassword,
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
                suffixIcon: IconButton(
                  tooltip: _obscureConfirm
                      ? widget.l10n.showPassword
                      : widget.l10n.hidePassword,
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              obscureText: _obscureConfirm,
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
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
                          ? l10n.signInToAccount
                          : l10n.createYourAccount,
                      key: ValueKey(isSignIn),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: theme.textTheme.labelLarge,
              unselectedLabelStyle: theme.textTheme.labelLarge,
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
