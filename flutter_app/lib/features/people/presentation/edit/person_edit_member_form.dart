import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/form/app_form_destructive_button.dart';
import '../../../../core/widgets/form/app_form_section.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/people_commands.dart';
import '../../domain/repositories/people_repository.dart';
import '../../domain/entities/household.dart';

class PersonEditMemberForm extends ConsumerStatefulWidget {
  const PersonEditMemberForm({
    super.key,
    required this.household,
    required this.memberUserId,
    required this.memberName,
  });

  final Household household;
  final String memberUserId;
  final String memberName;

  @override
  ConsumerState<PersonEditMemberForm> createState() =>
      _PersonEditMemberFormState();
}

class _PersonEditMemberFormState extends ConsumerState<PersonEditMemberForm> {
  bool _busy = false;

  Future<void> _removeMember({required bool removeAllPetAccess}) async {
    final l = AppLocalizations.of(context)!;
    HouseholdMemberRemovalPreview? preview;
    try {
      preview = await ref
          .read(peopleCommandsProvider)
          .memberRemovalPreview(
            householdId: widget.household.id,
            memberUserId: widget.memberUserId,
          );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.peopleRemoveError)));
      }
      return;
    }
    if (!mounted) return;

    final choice = await showDialog<_RemovalChoice>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.peopleMemberRemovalTitle),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.peopleMemberRemovalBody),
              if (preview!.remainingAccess.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(l.peopleMemberRemovalRemaining),
                for (final access in preview.remainingAccess)
                  Text('• ${access.petName} (${access.source})'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _RemovalChoice.householdOnly),
            child: Text(l.peopleMemberRemovalHouseholdOnly),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _RemovalChoice.allAccess),
            child: Text(l.peopleMemberRemovalAllAccess),
          ),
        ],
      ),
    );
    if (choice == null || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(peopleCommandsProvider)
          .removeHouseholdMember(
            householdId: widget.household.id,
            memberUserId: widget.memberUserId,
            removeAllAccessToMyPets: choice == _RemovalChoice.allAccess,
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
            widget.memberName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          AppFormSection(
            title: l.peopleDangerZoneTitle,
            children: [
              AppFormDestructiveButton(
                buttonKey: const Key('people_edit_remove_member'),
                label: l.peopleMemberRemovalAction,
                onPressed: _busy
                    ? null
                    : () => _removeMember(removeAllPetAccess: false),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _RemovalChoice { householdOnly, allAccess }
