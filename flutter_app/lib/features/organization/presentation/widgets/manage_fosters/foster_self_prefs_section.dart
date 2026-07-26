import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/foster_self_prefs.dart';
import '../../providers/foster_self_prefs_providers.dart';

class FosterSelfPrefsSection extends ConsumerStatefulWidget {
  const FosterSelfPrefsSection({
    super.key,
    required this.orgId,
    required this.initialPrefs,
  });

  final String orgId;
  final FosterSelfPrefs initialPrefs;

  @override
  ConsumerState<FosterSelfPrefsSection> createState() =>
      _FosterSelfPrefsSectionState();
}

class _FosterSelfPrefsSectionState
    extends ConsumerState<FosterSelfPrefsSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(fosterSelfPrefsProvider(widget.orgId).notifier)
          .loadFromParent(widget.initialPrefs);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final prefs = ref.watch(fosterSelfPrefsProvider(widget.orgId));
    final notifier = ref.read(fosterSelfPrefsProvider(widget.orgId).notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.fosterSelfPrefsTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<FosterVisibleTo>(
          key: const Key('foster_visible_to'),
          value: prefs.visibleTo,
          decoration: InputDecoration(
            labelText: l.fosterSelfPrefsVisibleToLabel,
            border: const OutlineInputBorder(),
          ),
          items: FosterVisibleTo.values
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(_visibleToLabel(l, value)),
                ),
              )
              .toList(),
          onChanged: (value) async {
            if (value == null) return;
            notifier.updateVisibleTo(value);
            await notifier.persist();
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<FosterAddressVisibility>(
          key: const Key('foster_address_visibility'),
          value: prefs.addressVisibility,
          decoration: InputDecoration(
            labelText: l.fosterSelfPrefsAddressVisibilityLabel,
            border: const OutlineInputBorder(),
          ),
          items: FosterAddressVisibility.values
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(_addressVisibilityLabel(l, value)),
                ),
              )
              .toList(),
          onChanged: (value) async {
            if (value == null) return;
            notifier.updateAddressVisibility(value);
            await notifier.persist();
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<FosterContactVisibility>(
          key: const Key('foster_contact_visibility'),
          value: prefs.contactVisibility,
          decoration: InputDecoration(
            labelText: l.fosterSelfPrefsContactVisibilityLabel,
            border: const OutlineInputBorder(),
          ),
          items: FosterContactVisibility.values
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(_contactVisibilityLabel(l, value)),
                ),
              )
              .toList(),
          onChanged: (value) async {
            if (value == null) return;
            notifier.updateContactVisibility(value);
            await notifier.persist();
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<FosterMessageNotificationChannel>(
          key: const Key('foster_message_channel'),
          value: prefs.messageChannel,
          decoration: InputDecoration(
            labelText: l.fosterSelfPrefsMessageChannelLabel,
            border: const OutlineInputBorder(),
          ),
          items: FosterMessageNotificationChannel.values
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(_messageChannelLabel(l, value)),
                ),
              )
              .toList(),
          onChanged: (value) async {
            if (value == null) return;
            notifier.updateMessageChannel(value);
            await notifier.persist();
          },
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          key: const Key('foster_rules_agreement'),
          value: prefs.hasRulesAgreement,
          onChanged: prefs.hasRulesAgreement
              ? (_) {
                  showFosterWithdrawAgreementDialog(
                    context: context,
                    ref: ref,
                    orgId: widget.orgId,
                  );
                }
              : null,
          title: Text(l.fosterRulesAgreementLabel),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  String _visibleToLabel(AppLocalizations l, FosterVisibleTo value) {
    return switch (value) {
      FosterVisibleTo.otherFosters => l.fosterSelfPrefsVisibleToOtherFosters,
      FosterVisibleTo.admins => l.fosterSelfPrefsVisibleToAdmins,
      FosterVisibleTo.both => l.fosterSelfPrefsVisibleToBoth,
      FosterVisibleTo.nobody => l.fosterSelfPrefsVisibleToNobody,
    };
  }

  String _addressVisibilityLabel(
    AppLocalizations l,
    FosterAddressVisibility value,
  ) {
    return switch (value) {
      FosterAddressVisibility.full => l.fosterSelfPrefsAddressFull,
      FosterAddressVisibility.town => l.fosterSelfPrefsAddressTown,
      FosterAddressVisibility.hidden => l.fosterSelfPrefsAddressHidden,
    };
  }

  String _contactVisibilityLabel(
    AppLocalizations l,
    FosterContactVisibility value,
  ) {
    return switch (value) {
      FosterContactVisibility.email => l.fosterSelfPrefsContactEmail,
      FosterContactVisibility.phone => l.fosterSelfPrefsContactPhone,
      FosterContactVisibility.neither => l.fosterSelfPrefsContactNeither,
      FosterContactVisibility.both => l.fosterSelfPrefsContactBoth,
    };
  }

  String _messageChannelLabel(
    AppLocalizations l,
    FosterMessageNotificationChannel value,
  ) {
    return switch (value) {
      FosterMessageNotificationChannel.inApp =>
        l.adminContactsMessageChannelInApp,
      FosterMessageNotificationChannel.email =>
        l.adminContactsMessageChannelEmail,
      FosterMessageNotificationChannel.both =>
        l.adminContactsMessageChannelBoth,
    };
  }
}

Future<void> showFosterWithdrawAgreementDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String orgId,
}) async {
  final l = AppLocalizations.of(context)!;
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        key: const Key('foster_withdraw_agreement_dialog'),
        title: Text(l.fosterWithdrawAgreementTitle),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.fosterWithdrawAgreementWarning),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('foster_withdraw_confirm_input'),
                controller: controller,
                decoration: InputDecoration(
                  labelText: l.fosterWithdrawAgreementConfirmLabel,
                  hintText: l.fosterWithdrawAgreementConfirmHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.trim() != 'withdraw') {
                    return l.fosterWithdrawAgreementConfirmHint;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            key: const Key('foster_withdraw_cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l.cancel),
          ),
          FilledButton(
            key: const Key('foster_withdraw_submit'),
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              final notifier = ref.read(
                fosterSelfPrefsProvider(orgId).notifier,
              );
              await notifier.withdrawAgreement(controller.text.trim());
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.fosterWithdrawAgreementSuccess)),
                );
              }
            },
            child: Text(l.fosterWithdrawAgreementSubmit),
          ),
        ],
      );
    },
  );
}
