import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/form/app_form_destructive_button.dart';
import '../../../../core/widgets/form/app_form_section.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/people_commands.dart';
import '../../domain/entities/household_invite.dart';

class PersonEditInviteForm extends ConsumerStatefulWidget {
  const PersonEditInviteForm({
    super.key,
    required this.invite,
    required this.householdId,
  });

  final HouseholdInvite invite;
  final String householdId;

  @override
  ConsumerState<PersonEditInviteForm> createState() =>
      _PersonEditInviteFormState();
}

class _PersonEditInviteFormState extends ConsumerState<PersonEditInviteForm> {
  bool _busy = false;

  Future<void> _revoke() async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.peopleRevokeInviteTitle),
        content: Text(l.peopleRevokeInviteBody(widget.invite.email)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.peopleRevokeInviteConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(peopleCommandsProvider)
          .revokeHouseholdInvite(
            householdId: widget.householdId,
            inviteId: widget.invite.id,
          );
      if (mounted) context.go('/pc/people');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.peopleRemoveError)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l.peopleEditPerson)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.invite.email,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          AppFormSection(
            title: l.peopleDangerZoneTitle,
            children: [
              AppFormDestructiveButton(
                buttonKey: const Key('people_edit_revoke_invite'),
                label: l.peopleRevokeInviteConfirm,
                onPressed: _busy ? null : _revoke,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
