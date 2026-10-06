import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/web/native_login.dart';
import '../../../../../core/web/native_login_inline_view.dart';
import '../../../../../l10n/app_localizations.dart';
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
      emailRequiredLabel: widget.l10n.emailRequired,
      passwordRequiredLabel: widget.l10n.passwordRequired,
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
