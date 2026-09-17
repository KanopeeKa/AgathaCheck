import 'package:flutter/material.dart';

import '../../../../core/widgets/form/app_form_labeled_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/pet_access.dart';

class ShareInviteForm extends StatefulWidget {
  const ShareInviteForm({
    required this.onSubmit,
    required this.isSending,
    this.petCount = 1,
  });

  final Future<void> Function(String email, PetAccessRole role) onSubmit;
  final bool isSending;
  final int petCount;

  @override
  State<ShareInviteForm> createState() => _ShareInviteFormState();
}

class _ShareInviteFormState extends State<ShareInviteForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  PetAccessRole _role = PetAccessRole.carer;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.shareInviteSectionTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            widget.petCount > 1
                ? l.shareInviteMultiPetHint(widget.petCount)
                : l.shareInviteSinglePetHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          AppFormLabeledField(
            label: l.recipientEmail,
            child: TextFormField(
              key: const Key('share_invite_email'),
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return l.orgInviteEmailRequired;
                if (!email.contains('@')) return l.orgInviteEmailInvalid;
                return null;
              },
            ),
          ),
          const SizedBox(height: 12),
          AppFormLabeledField(
            label: l.shareInviteRoleLabel,
            child: DropdownButtonFormField<PetAccessRole>(
              key: const Key('share_invite_role'),
              initialValue: _role,
              decoration: const InputDecoration(),
              items: [
                DropdownMenuItem(
                  value: PetAccessRole.carer,
                  child: Text(l.shareInviteRoleCarer),
                ),
                DropdownMenuItem(
                  value: PetAccessRole.coParent,
                  child: Text(l.coParent),
                ),
              ],
              onChanged: widget.isSending
                  ? null
                  : (value) {
                      if (value != null) setState(() => _role = value);
                    },
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('share_invite_send_button'),
            onPressed: widget.isSending ? null : _submit,
            icon: widget.isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text(l.shareInviteSend),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.onSubmit(_emailController.text.trim(), _role);
    if (mounted) _emailController.clear();
  }
}
