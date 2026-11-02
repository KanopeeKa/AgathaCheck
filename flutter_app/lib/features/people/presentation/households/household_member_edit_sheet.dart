import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../application/people_api_exception.dart';
import '../../application/people_commands.dart';
import '../../application/people_providers.dart';
import '../../domain/entities/household.dart';

Future<void> showHouseholdMemberEditSheet({
  required BuildContext context,
  required String householdId,
  required HouseholdMember member,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: _HouseholdMemberEditSheet(
        householdId: householdId,
        member: member,
      ),
    ),
  );
}

class _HouseholdMemberEditSheet extends ConsumerStatefulWidget {
  const _HouseholdMemberEditSheet({
    required this.householdId,
    required this.member,
  });

  final String householdId;
  final HouseholdMember member;

  @override
  ConsumerState<_HouseholdMemberEditSheet> createState() =>
      _HouseholdMemberEditSheetState();
}

class _HouseholdMemberEditSheetState
    extends ConsumerState<_HouseholdMemberEditSheet> {
  late String _tier;
  late bool _organiser;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tier = widget.member.tier;
    _organiser = widget.member.isOrganiser;
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      await ref
          .read(peopleCommandsProvider)
          .patchHouseholdMember(
            householdId: widget.householdId,
            memberUserId: widget.member.userId,
            accessTier: _organiser ? 'full_access' : _tier,
            isOrganiser: _organiser,
          );
      ref.invalidate(householdDetailProvider(widget.householdId));
      if (mounted) Navigator.pop(context);
    } on PeopleApiException catch (e) {
      if (mounted) {
        final message = e.code == 'last_organiser'
            ? l.peopleHouseholdLastOrganiserError
            : l.peopleSaveError;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
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
      key: Key('household_member_edit_${widget.member.userId}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.member.displayName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            DropdownMenu<String>(
              initialSelection: _tier,
              label: Text(l.peopleHouseholdInviteTierLabel),
              enabled: !_busy && !_organiser,
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
              onSelected: (value) {
                if (value != null) setState(() => _tier = value);
              },
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _organiser,
              onChanged: _busy
                  ? null
                  : (v) => setState(() {
                      _organiser = v == true;
                      if (_organiser) _tier = 'full_access';
                    }),
              title: Text(l.peopleHouseholdInviteOrganiserLabel),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l.save),
            ),
          ],
        ),
      ),
    );
  }
}
