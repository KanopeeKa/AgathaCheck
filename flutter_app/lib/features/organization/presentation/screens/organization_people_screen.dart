import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/services/admin_contacts.dart';
import '../../domain/services/foster_visibility.dart';
import '../../domain/services/org_people.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/organization_providers.dart';
import '../utils/org_people_route_params.dart';
import '../widgets/admin_contacts/admin_contact_invite_dialog.dart';
import '../widgets/org_people/org_people_bulk_actions_menu.dart';
import '../widgets/org_people/org_people_list.dart';
import '../widgets/org_shell_app_bar_title.dart';
import '../widgets/org_shell_scaffold.dart';

class OrganizationPeopleScreen extends ConsumerStatefulWidget {
  const OrganizationPeopleScreen({super.key, required this.orgId, this.filter});

  final String orgId;
  final String? filter;

  @override
  ConsumerState<OrganizationPeopleScreen> createState() =>
      _OrganizationPeopleScreenState();
}

class _OrganizationPeopleScreenState
    extends ConsumerState<OrganizationPeopleScreen> {
  String _searchQuery = '';
  bool _selectionMode = false;
  final Set<String> _selectedUserIds = {};

  bool get _adminsOnly => widget.filter == 'admins';

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedUserIds.clear();
    });
  }

  void _togglePersonSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  void _navigateToChangeRole() {
    if (_selectedUserIds.isEmpty) return;
    final peopleQuery = encodeOrgPeopleIdsQuery(_selectedUserIds);
    context.push(
      '/o/orgs/${widget.orgId}/customisations/roles?people=$peopleQuery',
    );
    _exitSelectionMode();
  }

  Future<void> _onboardSelectedAsFoster() async {
    if (_selectedUserIds.isEmpty) return;
    final l = AppLocalizations.of(context)!;
    try {
      await ref
          .read(orgPeopleProvider(widget.orgId).notifier)
          .onboardAsFoster(userIds: _selectedUserIds.toList());
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.orgFosterInviteSentInApp)));
      _exitSelectionMode();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  List<Widget> _buildContextualActions({
    required AppLocalizations l,
    required bool canManageAdmins,
    required bool canOnboardFoster,
  }) {
    final actions = <Widget>[];

    if (_selectionMode) {
      actions.add(
        TextButton(
          key: const Key('org_people_cancel_select'),
          onPressed: _exitSelectionMode,
          child: Text(l.cancel),
        ),
      );
      if (_selectedUserIds.isNotEmpty) {
        actions.add(
          OrgPeopleBulkActionsMenu(
            selectedCount: _selectedUserIds.length,
            onChangeRole: _navigateToChangeRole,
            onOnboardFoster: _onboardSelectedAsFoster,
            canOnboardFoster: canOnboardFoster,
          ),
        );
      }
    } else {
      actions.add(
        IconButton(
          key: const Key('org_people_select_toggle'),
          icon: const Icon(Icons.checklist),
          tooltip: l.orgPeopleSelect,
          onPressed: () => setState(() => _selectionMode = true),
        ),
      );
      if (canManageAdmins) {
        actions.add(
          IconButton(
            key: const Key('admin_contacts_add'),
            icon: const Icon(Icons.person_add),
            tooltip: l.adminContactsAddAdmin,
            onPressed: () => showAdminContactInviteDialog(
              context: context,
              ref: ref,
              orgId: widget.orgId,
            ),
          ),
        );
      }
    }

    return actions;
  }

  @override
  Widget build(BuildContext context) {
    final peopleAsync = ref.watch(orgPeopleProvider(widget.orgId));
    final viewerRole = ref.watch(orgViewerRoleProvider(widget.orgId));
    final viewerUserId = ref.watch(authProvider.select((s) => s.user?.id));
    final canManageAdmins =
        _adminsOnly && canManageAdminContacts(viewerRole, widget.orgId);
    final canOnboardFoster = canManageFosters(viewerRole, widget.orgId);
    final colorScheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final baseTitle = _adminsOnly ? l.adminContactsTitle : l.people;
    final title = _selectionMode && _selectedUserIds.isNotEmpty
        ? l.orgPeopleSelectedCount(_selectedUserIds.length)
        : baseTitle;

    return OrgShellScaffold(
      title: title,
      orgId: widget.orgId,
      navVariant: OrgNavTitleVariant.withOrgLogo,
      leadingKey: Key(_adminsOnly ? 'admin_contacts_back' : 'org_people_back'),
      contextualActions: _buildContextualActions(
        l: l,
        canManageAdmins: canManageAdmins,
        canOnboardFoster: canOnboardFoster,
      ),
      child: peopleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text('$e'),
              const SizedBox(height: 8),
              ElevatedButton(
                key: Key(
                  _adminsOnly ? 'admin_contacts_retry' : 'org_people_retry',
                ),
                onPressed: () =>
                    ref.invalidate(orgPeopleProvider(widget.orgId)),
                child: Text(l.retry),
              ),
            ],
          ),
        ),
        data: (people) {
          final routeFiltered = filterOrgPeopleByRoute(
            people,
            filter: widget.filter,
          );
          final nameFiltered = filterOrgPeopleByName(
            routeFiltered,
            _searchQuery,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                key: const Key('org_people_search'),
                decoration: InputDecoration(
                  labelText: l.orgPeopleSearchPlaceholder,
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              if (_searchQuery.trim().isNotEmpty && nameFiltered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      l.orgPeopleSearchEmpty,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                OrgPeopleList(
                  orgId: widget.orgId,
                  people: nameFiltered,
                  viewerUserId: viewerUserId,
                  adminsOnly: _adminsOnly,
                  selectionMode: _selectionMode,
                  selectedUserIds: _selectedUserIds,
                  onPersonSelectionToggle: _togglePersonSelection,
                ),
            ],
          );
        },
      ),
    );
  }
}
