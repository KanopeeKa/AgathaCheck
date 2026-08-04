import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/org_person.dart';
import '../providers/organization_providers.dart';
import '../widgets/org_shell_app_bar_title.dart';
import '../widgets/org_shell_scaffold.dart';
import '../widgets/foster_pet_mini_card.dart';
import '../widgets/organization_role_labels.dart';
import '../widgets/org_person_card.dart';

class OrganizationPersonDetailScreen extends ConsumerStatefulWidget {
  const OrganizationPersonDetailScreen({
    super.key,
    required this.orgId,
    required this.kind,
    required this.recordId,
  });

  final String orgId;
  final String kind;
  final String recordId;

  @override
  ConsumerState<OrganizationPersonDetailScreen> createState() =>
      _OrganizationPersonDetailScreenState();
}

class _OrganizationPersonDetailScreenState
    extends ConsumerState<OrganizationPersonDetailScreen> {
  late final OrgPersonDetailKey _key;

  @override
  void initState() {
    super.initState();
    _key = (
      orgId: widget.orgId,
      kind: OrgPersonKind.fromWire(widget.kind),
      recordId: widget.recordId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(orgPersonDetailProvider(_key));
    final isOrgAdmin = ref.watch(isOrgAdminProvider(widget.orgId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    return OrgShellScaffold(
      title: detailAsync.maybeWhen(
        data: (person) => l.orgPersonProfileTitle(person.displayName),
        orElse: () => l.people,
      ),
      orgId: widget.orgId,
      navVariant: OrgNavTitleVariant.withOrgLogo,
      trailingActions: [
        if (isOrgAdmin)
          PopupMenuButton<String>(
            onSelected: (action) => _handleAdminAction(context, action),
            itemBuilder: (context) {
              final person = detailAsync.valueOrNull;
              if (person == null || person.isExternal || person.isPending) {
                if (person?.isExternal == true) {
                  return [
                    PopupMenuItem(
                      value: 'delete_external',
                      child: Text(
                        l.deleteFosterParent,
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                  ];
                }
                return const [];
              }
              return [
                PopupMenuItem(
                  value: 'change_role',
                  child: Text(l.orgChangeRole),
                ),
                PopupMenuItem(
                  value: 'remove',
                  child: Text(
                    l.orgRemoveMember,
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
              ];
            },
          ),
      ],
      child: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (person) {
          final roleLabel = person.isExternal
              ? l.fosterParentNoAccount
              : person.role != null
              ? localizedOrgMemberRole(l, person.role!)
              : '';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              OrgPersonCard(
                person: person,
                orgId: widget.orgId,
                localizedRoleLabel: localizedOrgMemberRole,
              ),
              const SizedBox(height: 16),
              Card(
                color: colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(label: l.email, value: person.email ?? '—'),
                      const SizedBox(height: 8),
                      _InfoRow(label: l.orgChangeRole, value: roleLabel),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: l.phone,
                        value: person.fosterPhone.isNotEmpty
                            ? person.fosterPhone
                            : '—',
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: l.fosterContactAddress,
                        value: person.fosterAddress.isNotEmpty
                            ? person.fosterAddress
                            : '—',
                      ),
                      if (person.adminNotes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _InfoRow(label: l.notes, value: person.adminNotes),
                      ],
                      if (isOrgAdmin) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => _editContact(context, person),
                          icon: const Icon(Icons.edit, size: 18),
                          label: Text(l.editFosterContact),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l.currentlyFostering,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (person.currentPlacements.isEmpty)
                Text(
                  l.fosterPlacementNotInFoster,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                )
              else
                ...person.currentPlacements.map(
                  (placement) => FosterPetMiniCard(
                    petName: placement.petName,
                    statusLabel: localizedPlacementStatus(l, placement),
                    startDate: placement.startDate,
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                l.previouslyFostered,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (person.pastPlacements.isEmpty)
                Text(
                  l.noPreviousFosterPlacements,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                )
              else
                ...person.pastPlacements.map(
                  (item) => FosterPetMiniCard(
                    petName: item.placement.petName,
                    statusLabel: localizedPlacementStatus(l, item.placement),
                    startDate: item.placement.startDate,
                    outcomeLabel: item.outcome != null
                        ? localizedPlacementOutcome(l, item.outcome!)
                        : null,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editContact(
    BuildContext context,
    OrgPersonDetail person,
  ) async {
    final l = AppLocalizations.of(context)!;
    final phoneController = TextEditingController(text: person.fosterPhone);
    final addressController = TextEditingController(text: person.fosterAddress);
    final notesController = TextEditingController(text: person.adminNotes);
    final nameController = TextEditingController(text: person.displayName);
    final emailController = TextEditingController(text: person.email ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.editFosterContact),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (person.isExternal) ...[
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l.fosterParentDisplayName,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: l.email),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: phoneController,
                decoration: InputDecoration(labelText: l.phone),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: addressController,
                decoration: InputDecoration(labelText: l.fosterContactAddress),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: l.notes,
                  helperText: l.orgNotesOperationalOnly,
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.save),
          ),
        ],
      ),
    );

    if (saved != true || !mounted) return;

    await ref
        .read(orgPersonDetailProvider(_key).notifier)
        .updateContact(
          fosterPhone: phoneController.text.trim(),
          fosterAddress: addressController.text.trim(),
          adminNotes: notesController.text.trim(),
          displayName: person.isExternal ? nameController.text.trim() : null,
          email: person.isExternal ? emailController.text.trim() : null,
        );

    phoneController.dispose();
    addressController.dispose();
    notesController.dispose();
    nameController.dispose();
    emailController.dispose();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.fosterContactSaved)));
    }
  }

  Future<void> _handleAdminAction(BuildContext context, String action) async {
    final person = ref.read(orgPersonDetailProvider(_key)).valueOrNull;
    if (person == null) return;
    final l = AppLocalizations.of(context)!;

    switch (action) {
      case 'delete_external':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l.deleteFosterParent),
            content: Text(l.deleteFosterParentConfirm(person.displayName)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  l.delete,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
        );
        if (confirmed == true && mounted) {
          await ref
              .read(orgPeopleProvider(widget.orgId).notifier)
              .deleteExternal(person.recordId);
          if (mounted) context.pop();
        }
        break;
      case 'change_role':
        await _showChangeRoleDialog(
          context,
          person,
          ref.read(isOrgSuperUserProvider(widget.orgId)),
        );
        break;
      case 'remove':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l.orgRemoveMember),
            content: Text(l.orgRemoveMemberConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  l.delete,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
        );
        if (confirmed == true && person.userId != null && mounted) {
          await ref
              .read(orgPersonDetailProvider(_key).notifier)
              .removeMember(person.userId!);
          if (mounted) context.pop();
        }
        break;
    }
  }

  Future<void> _showChangeRoleDialog(
    BuildContext context,
    OrgPersonDetail person,
    bool isSuperAdmin,
  ) async {
    final l = AppLocalizations.of(context)!;
    final options = invitableRoleWires(isSuperAdmin: isSuperAdmin);
    String selectedRole = person.role?.toWire() ?? options.first;
    if (!options.contains(selectedRole)) {
      selectedRole = options.first;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l.orgSelectNewRole),
          content: DropdownButtonFormField<String>(
            value: selectedRole,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: options
                .map(
                  (wire) => DropdownMenuItem(
                    value: wire,
                    child: Text(invitableRoleLabel(l, wire)),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => selectedRole = v);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () async {
                if (person.userId == null) return;
                await ref
                    .read(orgPersonDetailProvider(_key).notifier)
                    .updateMemberRole(person.userId!, selectedRole);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(l.save),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(value, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
