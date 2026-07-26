import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/admin_contact_self_prefs.dart';
import '../../providers/admin_contact_providers.dart';

/// Self-management prefs stub on the pinned admin self-card.
class AdminContactSelfPrefsSection extends ConsumerWidget {
  const AdminContactSelfPrefsSection({super.key, required this.orgId});

  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final prefs = ref.watch(adminContactSelfPrefsProvider(orgId));
    final notifier = ref.read(adminContactSelfPrefsProvider(orgId).notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.adminContactsSelfPrefsTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l.adminContactsSelfPrefsStubNote,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<AdminPhoneVisibility>(
          key: const Key('admin_contact_phone_visibility'),
          value: prefs.phoneVisibility,
          decoration: InputDecoration(
            labelText: l.adminContactsPhoneVisibilityLabel,
            border: const OutlineInputBorder(),
          ),
          items: AdminPhoneVisibility.values
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(_phoneVisibilityLabel(l, value)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) notifier.updatePhoneVisibility(value);
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<AdminMessageNotificationChannel>(
          key: const Key('admin_contact_message_channel'),
          value: prefs.messageChannel,
          decoration: InputDecoration(
            labelText: l.adminContactsMessageChannelLabel,
            border: const OutlineInputBorder(),
          ),
          items: AdminMessageNotificationChannel.values
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(_messageChannelLabel(l, value)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) notifier.updateMessageChannel(value);
          },
        ),
      ],
    );
  }

  String _phoneVisibilityLabel(AppLocalizations l, AdminPhoneVisibility value) {
    return switch (value) {
      AdminPhoneVisibility.fosters => l.adminContactsPhoneVisibilityFosters,
      AdminPhoneVisibility.admins => l.adminContactsPhoneVisibilityAdmins,
      AdminPhoneVisibility.all => l.adminContactsPhoneVisibilityAll,
      AdminPhoneVisibility.nobody => l.adminContactsPhoneVisibilityNobody,
    };
  }

  String _messageChannelLabel(
    AppLocalizations l,
    AdminMessageNotificationChannel value,
  ) {
    return switch (value) {
      AdminMessageNotificationChannel.inApp =>
        l.adminContactsMessageChannelInApp,
      AdminMessageNotificationChannel.email =>
        l.adminContactsMessageChannelEmail,
      AdminMessageNotificationChannel.both =>
        l.adminContactsMessageChannelBoth,
    };
  }
}
