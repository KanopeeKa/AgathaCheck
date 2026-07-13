import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/organization_providers.dart';
import 'organization_role_labels.dart';

/// Email-only org invite. Matches `POST /api/organizations/:id/invite`.
Future<void> showOrganizationInviteByEmailDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String orgId,
}) async {
  final l = AppLocalizations.of(context)!;
  final isSuperAdmin = ref.read(isOrgSuperUserProvider(orgId));
  final roleOptions = invitableRoleWires(isSuperAdmin: isSuperAdmin);
  final emailController = TextEditingController();
  String selectedRole = roleOptions.first;
  final formKey = GlobalKey<FormState>();

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(l.addUser),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.enterEmail, style: Theme.of(ctx).textTheme.bodySmall),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('org_invite_email'),
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return l.orgInviteEmailRequired;
                  if (!email.contains('@')) return l.orgInviteEmailInvalid;
                  return null;
                },
                decoration: InputDecoration(
                  labelText: l.email,
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(l.selectRole, style: Theme.of(ctx).textTheme.bodySmall),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: InputDecoration(
                  labelText: l.selectRole,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: roleOptions
                    .map(
                      (wire) => DropdownMenuItem(
                        value: wire,
                        child: Text(invitableRoleLabel(l, wire)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => selectedRole = value);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            key: const Key('org_invite_send'),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final email = emailController.text.trim();
              Navigator.pop(ctx);
              try {
                await ref
                    .read(orgMembersProvider(orgId).notifier)
                    .inviteByEmail(email, selectedRole);
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l.inviteSent)));
                }
              } catch (e) {
                if (context.mounted) {
                  final errorMsg = e.toString();
                  String displayMsg = errorMsg;
                  if (errorMsg.contains('user_not_found') ||
                      errorMsg.contains('User not found')) {
                    displayMsg = l.userNotFound;
                  } else if (errorMsg.contains('already_member')) {
                    displayMsg = l.alreadyMember;
                  }
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(displayMsg)));
                }
              }
            },
            child: Text(l.sendInvite),
          ),
        ],
      ),
    ),
  );

  emailController.dispose();
}
