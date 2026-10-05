import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../auth/auth.dart';
import '../../../pet_profile/pet_profile.dart';
import '../../application/people_commands.dart';
import '../../application/people_providers.dart';
import '../../domain/entities/household.dart';
import '../../domain/entities/household_invite.dart';
import '../../domain/entities/roster.dart';
import '../../domain/repositories/people_repository.dart';
import 'household_invite_member_sheet.dart';
import 'household_member_removal_dialog.dart';
import 'household_tier_labels.dart';

class HouseholdDetailPage extends ConsumerWidget {
  const HouseholdDetailPage({
    super.key,
    required this.householdId,
    this.embedded = false,
  });

  final String householdId;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final detailAsync = ref.watch(householdDetailProvider(householdId));
    final roster = ref.watch(rosterProvider).valueOrNull;

    return detailAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: Text(l.peopleListLoadError)),
      data: (household) {
        if (household == null) {
          return Center(child: Text(l.peopleDetailNotFound));
        }
        return _HouseholdDetailBody(
          household: household,
          roster: roster,
          embedded: embedded,
        );
      },
    );
  }
}

class _HouseholdDetailBody extends ConsumerStatefulWidget {
  const _HouseholdDetailBody({
    required this.household,
    required this.roster,
    required this.embedded,
  });

  final Household household;
  final Roster? roster;
  final bool embedded;

  @override
  ConsumerState<_HouseholdDetailBody> createState() =>
      _HouseholdDetailBodyState();
}

class _HouseholdDetailBodyState extends ConsumerState<_HouseholdDetailBody> {
  bool _busy = false;

  List<HouseholdInvite> _pendingInvites() {
    final roster = widget.roster;
    if (roster == null) return const [];
    return roster.pendingInvites
        .where(
          (i) =>
              i.source == 'household' && i.householdId == widget.household.id,
        )
        .toList();
  }

  Future<void> _rename() async {
    final l = AppLocalizations.of(context)!;
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController(text: widget.household.name);
        return AlertDialog(
          title: Text(l.peopleHouseholdRenameTitle),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: l.householdNameLabel),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text(l.save),
            ),
          ],
        );
      },
    );
    if (name == null || name.isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(peopleCommandsProvider)
          .renameHousehold(householdId: widget.household.id, name: name);
      ref.invalidate(householdDetailProvider(widget.household.id));
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

  Future<void> _togglePet(String petId, bool include) async {
    final l = AppLocalizations.of(context)!;
    final current = widget.household.pets.map((p) => p.petId).toSet();
    if (include) {
      current.add(petId);
    } else {
      current.remove(petId);
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(peopleCommandsProvider)
          .setHouseholdPets(
            householdId: widget.household.id,
            petIds: current.toList(),
          );
      ref.invalidate(householdDetailProvider(widget.household.id));
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

  Future<void> _revokeInvite(HouseholdInvite invite) async {
    final l = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      await ref
          .read(peopleCommandsProvider)
          .revokeHouseholdInvite(
            householdId: widget.household.id,
            inviteId: invite.id,
          );
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

  Future<void> _removeMember({
    required HouseholdMember member,
    required bool removingSelf,
  }) async {
    final l = AppLocalizations.of(context)!;
    HouseholdMemberRemovalPreview? preview;
    try {
      preview = await ref
          .read(peopleCommandsProvider)
          .memberRemovalPreview(
            householdId: widget.household.id,
            memberUserId: member.userId,
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

    final successors = widget.household.members
        .where((m) => m.userId != member.userId)
        .toList();
    final result = await showHouseholdMemberRemovalDialog(
      context: context,
      preview: preview,
      successorCandidates: successors,
      removingSelf: removingSelf,
    );
    if (result == null || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(peopleCommandsProvider)
          .removeHouseholdMember(
            householdId: widget.household.id,
            memberUserId: member.userId,
            removeAllAccessToMyPets:
                result.choice == HouseholdRemovalChoice.allAccess,
            successorUserId: result.successorUserId,
          );
      if (removingSelf && mounted) {
        context.go('/pc/people/households');
      } else {
        ref.invalidate(householdDetailProvider(widget.household.id));
      }
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
    final household = widget.household;
    final authUserId = ref.watch(authProvider).user?.id;
    final myMember = household.members
        .where((m) => m.isYou || m.userId == authUserId)
        .firstOrNull;
    final petsAsync = ref.watch(petListProvider);
    final myPets = (petsAsync.valueOrNull ?? const <Pet>[]);

    final content = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                household.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            if (household.myIsOrganiser)
              IconButton(
                key: const Key('household_rename'),
                tooltip: l.peopleHouseholdRenameTitle,
                onPressed: _busy ? null : _rename,
                icon: const Icon(Icons.edit_outlined),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          householdTierLabel(
            l,
            household.myTier,
            organiser: household.myIsOrganiser,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l.peopleHouseholdMembersTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final member in household.members)
          ListTile(
            key: Key('household_member_${member.userId}'),
            title: Text(member.displayName),
            subtitle: Text(
              householdTierLabel(l, member.tier, organiser: member.isOrganiser),
            ),
            trailing: household.myIsOrganiser && !member.isYou
                ? IconButton(
                    tooltip: l.peopleMemberRemovalAction,
                    onPressed: _busy
                        ? null
                        : () => _removeMember(
                            member: member,
                            removingSelf: false,
                          ),
                    icon: const Icon(Icons.person_remove_outlined),
                  )
                : null,
          ),
        if (household.myIsOrganiser) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('household_invite_member'),
            onPressed: _busy
                ? null
                : () => showHouseholdInviteMemberSheet(
                    context: context,
                    householdId: household.id,
                  ),
            icon: const Icon(Icons.person_add_alt_outlined),
            label: Text(l.peopleHouseholdInviteMemberAction),
          ),
        ],
        if (_pendingInvites().isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            l.peopleHouseholdPendingInvitesTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final invite in _pendingInvites())
            ListTile(
              key: Key('household_pending_invite_${invite.id}'),
              title: Text(invite.email),
              trailing: household.myIsOrganiser
                  ? TextButton(
                      key: Key('household_revoke_${invite.id}'),
                      onPressed: _busy ? null : () => _revokeInvite(invite),
                      child: Text(l.peopleHouseholdRevokeInvite),
                    )
                  : null,
            ),
        ],
        const SizedBox(height: 24),
        Text(
          l.peopleHouseholdPetsTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final pet in myPets)
          CheckboxListTile(
            key: Key('household_pet_${pet.id}'),
            value: household.pets.any((p) => p.petId == pet.id),
            onChanged: _busy ? null : (v) => _togglePet(pet.id, v == true),
            title: Text(pet.name),
            subtitle: Text(l.peopleHouseholdPetOwnerYou),
          ),
        for (final pet in household.pets.where(
          (p) => !myPets.any((mine) => mine.id == p.petId),
        ))
          ListTile(
            title: Text(pet.name),
            subtitle: Text(l.peopleHouseholdPetOtherOwner),
          ),
        if (myMember != null) ...[
          const SizedBox(height: 24),
          OutlinedButton(
            key: const Key('household_leave'),
            onPressed: _busy
                ? null
                : () => _removeMember(member: myMember, removingSelf: true),
            child: Text(l.peopleHouseholdLeaveAction),
          ),
        ],
      ],
    );

    if (widget.embedded) {
      return AbsorbPointer(absorbing: _busy, child: content);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.householdsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/pc/people/households'),
        ),
      ),
      body: AbsorbPointer(absorbing: _busy, child: content),
    );
  }
}
