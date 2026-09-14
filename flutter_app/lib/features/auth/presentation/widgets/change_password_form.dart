import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/widgets/form/app_form_labeled_field.dart';
import '../../../../core/widgets/form/app_form_section.dart';

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
            child: AppFormSection(
              title: l10nChangePassword,
              children: [
                AppFormLabeledField(
                  label: l10nCurrentPassword,
                  child: TextFormField(
                    controller: currentPasswordController,
                    decoration: InputDecoration(
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
                ),
                const SizedBox(height: 16),
                AppFormLabeledField(
                  label: l10nNewPassword,
                  child: TextFormField(
                    controller: newPasswordController,
                    decoration: InputDecoration(
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
                ),
                const SizedBox(height: 16),
                AppFormLabeledField(
                  label: l10nConfirmNewPassword,
                  child: TextFormField(
                    controller: confirmPasswordController,
                    decoration: const InputDecoration(),
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: (v) {
                      if (v != newPasswordController.text) {
                        return l10nPasswordsDoNotMatch;
                      }
                      return null;
                    },
                  ),
                ),
                if (passwordMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: passwordSuccess
                          ? AppColorTokens.successLight
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
                              ? AppColorTokens.success
                              : theme.colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            passwordMessage!,
                            style: TextStyle(
                              color: passwordSuccess
                                  ? AppColorTokens.success
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
                  child: FilledButton(
                    key: const Key('change_password_button'),
                    onPressed: changingPassword ? null : onChangePassword,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
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
