import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../providers/auth_providers.dart';
import 'landing_error_banner.dart';

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
