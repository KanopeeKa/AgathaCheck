import 'package:flutter/material.dart';

class ChangePasswordForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final bool obscureCurrent;
  final bool obscureNew;
  final bool changingPassword;
  final String? passwordMessage;
  final bool passwordSuccess;
  final VoidCallback onChangePassword;
  final VoidCallback onToggleObscureCurrent;
  final VoidCallback onToggleObscureNew;
  final String l10nChangePassword;
  final String l10nCurrentPassword;
  final String l10nShowCurrentPassword;
  final String l10nHideCurrentPassword;
  final String l10nCurrentPasswordRequired;
  final String l10nNewPassword;
  final String l10nShowNewPassword;
  final String l10nHideNewPassword;
  final String l10nNewPasswordRequired;
  final String l10nAtLeast6Characters;
  final String l10nConfirmNewPassword;
  final String l10nPasswordsDoNotMatch;

  const ChangePasswordForm({
    super.key,
    required this.formKey,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.obscureCurrent,
    required this.obscureNew,
    required this.changingPassword,
    required this.passwordMessage,
    required this.passwordSuccess,
    required this.onChangePassword,
    required this.onToggleObscureCurrent,
    required this.onToggleObscureNew,
    required this.l10nChangePassword,
    required this.l10nCurrentPassword,
    required this.l10nShowCurrentPassword,
    required this.l10nHideCurrentPassword,
    required this.l10nCurrentPasswordRequired,
    required this.l10nNewPassword,
    required this.l10nShowNewPassword,
    required this.l10nHideNewPassword,
    required this.l10nNewPasswordRequired,
    required this.l10nAtLeast6Characters,
    required this.l10nConfirmNewPassword,
    required this.l10nPasswordsDoNotMatch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: AutofillGroup(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10nChangePassword, style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                TextFormField(
                  controller: currentPasswordController,
                  decoration: InputDecoration(
                    labelText: l10nCurrentPassword,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      tooltip: obscureCurrent
                          ? l10nShowCurrentPassword
                          : l10nHideCurrentPassword,
                      icon: Icon(
                        obscureCurrent
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: onToggleObscureCurrent,
                    ),
                  ),
                  obscureText: obscureCurrent,
                  autofillHints: const [AutofillHints.password],
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return l10nCurrentPasswordRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: newPasswordController,
                  decoration: InputDecoration(
                    labelText: l10nNewPassword,
                    prefixIcon: const Icon(Icons.lock_reset),
                    suffixIcon: IconButton(
                      tooltip: obscureNew
                          ? l10nShowNewPassword
                          : l10nHideNewPassword,
                      icon: Icon(
                        obscureNew ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: onToggleObscureNew,
                    ),
                  ),
                  obscureText: obscureNew,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return l10nNewPasswordRequired;
                    }
                    if (v.length < 6) {
                      return l10nAtLeast6Characters;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: l10nConfirmNewPassword,
                    prefixIcon: const Icon(Icons.lock_reset),
                  ),
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (v) {
                    if (v != newPasswordController.text) {
                      return l10nPasswordsDoNotMatch;
                    }
                    return null;
                  },
                ),
                if (passwordMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: passwordSuccess
                          ? Colors.green.shade50
                          : theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          passwordSuccess
                              ? Icons.check_circle
                              : Icons.error_outline,
                          color: passwordSuccess
                              ? Colors.green
                              : theme.colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            passwordMessage!,
                            style: TextStyle(
                              color: passwordSuccess
                                  ? Colors.green.shade800
                                  : theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    key: const Key('change_password_button'),
                    onPressed: changingPassword ? null : onChangePassword,
                    child: changingPassword
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10nChangePassword),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
