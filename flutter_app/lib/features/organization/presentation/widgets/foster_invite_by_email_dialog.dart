import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/org_provider_people.dart';

Future<void> showFosterInviteByEmailDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String orgId,
}) async {
  final l = AppLocalizations.of(context)!;
  final emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.orgFosterInviteByEmailTitle),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.orgFosterInviteByEmailDescription,
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('foster_invite_email'),
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return l.orgInviteEmailRequired;
                if (!email.contains('@')) return l.orgInviteEmailInvalid;
                return null;
              },
              decoration: InputDecoration(
                labelText: l.email,
                prefixIcon: const Icon(Icons.email),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('foster_invite_send'),
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            try {
              final result = await ref
                  .read(orgPeopleProvider(orgId).notifier)
                  .onboardAsFoster(email: emailController.text.trim());
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              if (!context.mounted) return;
              final channel = result['channel']?.toString();
              final message = channel == 'email'
                  ? l.orgFosterInviteSentEmail
                  : l.orgFosterInviteSentInApp;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            } catch (e) {
              if (!ctx.mounted) return;
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e')));
            }
          },
          child: Text(l.sendInvite),
        ),
      ],
    ),
  );
}
