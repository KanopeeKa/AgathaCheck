import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../application/people_commands.dart';

Future<void> showHouseholdInviteMemberSheet({
  required BuildContext context,
  required String householdId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: _HouseholdInviteMemberSheet(householdId: householdId),
    ),
  );
}

class _HouseholdInviteMemberSheet extends ConsumerStatefulWidget {
  const _HouseholdInviteMemberSheet({required this.householdId});

  final String householdId;

  @override
  ConsumerState<_HouseholdInviteMemberSheet> createState() =>
      _HouseholdInviteMemberSheetState();
}

class _HouseholdInviteMemberSheetState
    extends ConsumerState<_HouseholdInviteMemberSheet> {
  final _emailController = TextEditingController();
  String _tier = 'full_access';
  bool _organiser = false;
  bool _adultConfirmed = false;
  bool _busy = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    if (email.isEmpty || !_adultConfirmed) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(peopleCommandsProvider)
          .createHouseholdInvite(
            householdId: widget.householdId,
            inviteeEmail: email,
            accessTier: _organiser ? 'full_access' : _tier,
            isOrganiser: _organiser,
          );
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.peopleHouseholdInviteSent)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.peopleSaveError)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SafeArea(
      key: const Key('household_invite_sheet'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.peopleHouseholdInviteMemberTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('household_invite_email'),
              controller: _emailController,
              decoration: InputDecoration(labelText: l.email),
              keyboardType: TextInputType.emailAddress,
              enabled: !_busy,
            ),
            const SizedBox(height: 8),
            DropdownMenu<String>(
              initialSelection: _tier,
              label: Text(l.peopleHouseholdInviteTierLabel),
              dropdownMenuEntries: [
                DropdownMenuEntry(
                  value: 'full_access',
                  label: l.householdFullAccessLabel,
                ),
                DropdownMenuEntry(
                  value: 'can_log_care',
                  label: l.householdCanLogCareLabel,
                ),
              ],
              onSelected: _organiser
                  ? null
                  : (v) {
                      if (v != null) setState(() => _tier = v);
                    },
            ),
            CheckboxListTile(
              value: _organiser,
              onChanged: _busy
                  ? null
                  : (v) => setState(() => _organiser = v == true),
              title: Text(l.peopleHouseholdInviteOrganiserLabel),
            ),
            CheckboxListTile(
              value: _adultConfirmed,
              onChanged: _busy
                  ? null
                  : (v) => setState(() => _adultConfirmed = v == true),
              title: Text(l.peopleHouseholdInviteAdultConfirm),
            ),
            const SizedBox(height: 8),
            FilledButton(
              key: const Key('household_invite_submit'),
              onPressed: _busy || !_adultConfirmed ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l.peopleHouseholdInviteMemberAction),
            ),
          ],
        ),
      ),
    );
  }
}
