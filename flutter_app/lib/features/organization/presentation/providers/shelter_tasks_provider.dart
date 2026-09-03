import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/foster_request.dart';
import '../../domain/entities/organization.dart';
import '../../domain/entities/organization_member.dart';
import '../../domain/services/org_permissions.dart';
import 'foster_requests_providers.dart';
import 'fostering_sessions_providers.dart';
import 'org_permissions_providers.dart';
import 'org_provider_invites.dart';
import 'org_provider_list.dart';
import 'org_provider_people.dart';
import 'org_provider_pets.dart';
import '../utils/org_pets_care_utils.dart';
import '../widgets/shelter_tasks/shelter_task_item.dart';

const shelterTasksPreviewMaxRows = 8;

class ShelterTasksPreviewNotifier
    extends AsyncNotifier<ShelterTasksPreviewData> {
  @override
  Future<ShelterTasksPreviewData> build() async {
    final orgs = await ref.watch(organizationListProvider.future);
    final invites = await ref.watch(pendingOrgInvitesProvider.future);

    final tasks = <ShelterTaskItem>[
      ..._inviteTasks(invites),
      ...await _membershipTasks(orgs),
    ]..sort((a, b) {
      final order = a.sortOrder.compareTo(b.sortOrder);
      if (order != 0) return order;
      return a.title.compareTo(b.title);
    });

    return ShelterTasksPreviewData(
      previewTasks: tasks.take(shelterTasksPreviewMaxRows).toList(growable: false),
      totalTaskCount: tasks.length,
    );
  }

  List<ShelterTaskItem> _inviteTasks(List<PendingOrgInvite> invites) {
    return invites
        .map(
          (invite) => ShelterTaskItem(
            id: 'invite-${invite.id}',
            kind: ShelterTaskKind.pendingInvite,
            orgId: invite.organizationId,
            orgName: invite.organizationName,
            title: invite.organizationName,
            subtitle: invite.desiredRole,
            routePath: '/o/orgs/${invite.organizationId}',
            sortOrder: 0,
            invite: invite,
          ),
        )
        .toList(growable: false);
  }

  Future<List<ShelterTaskItem>> _membershipTasks(List<Organization> orgs) async {
    final results = await Future.wait(
      orgs.map(_loadOrgTasks),
      eagerError: false,
    );
    return results.expand((tasks) => tasks).toList(growable: false);
  }

  Future<List<ShelterTaskItem>> _loadOrgTasks(Organization org) async {
    final role = OrgMemberRole.fromWire(org.role);
    final tasks = <ShelterTaskItem>[];

    if (await _viewerCan(org, 'view_org_pets')) {
      tasks.addAll(await _petAttentionTasks(org));
    }
    if (await _viewerCan(org, 'review_foster_onboarding')) {
      tasks.addAll(await _fosterOnboardingTasks(org));
    }
    if (await _viewerCan(org, 'contact_fosters')) {
      tasks.addAll(await _fosterRequestTasks(org));
    } else if (role.isFoster || org.isFoster) {
      tasks.addAll(await _fosterRespondTasks(org));
    }

    return tasks;
  }

  Future<bool> _viewerCan(Organization org, String permissionKey) async {
    await ref.watch(orgEffectivePermissionsProvider(org.id).future);
    return hasPermission(
      OrgMemberRole.fromWire(org.role),
      org.id,
      permissionKey,
    );
  }

  Future<List<ShelterTaskItem>> _petAttentionTasks(Organization org) async {
    final pets = await ref.watch(orgPetsProvider(org.id).future);
    final placements = await ref.watch(fosteringSessionsListProvider(org.id).future);
    final tasks = <ShelterTaskItem>[];

    for (final pet in pets) {
      final reason = needAttentionReason(
        pet,
        placements,
        fosterEndDate: pet.fosterEndDate,
      );
      if (reason == null) continue;

      tasks.add(
        ShelterTaskItem(
          id: 'pet-${org.id}-${pet.id}',
          kind: ShelterTaskKind.petNeedAttention,
          orgId: org.id,
          orgName: org.name,
          title: pet.name,
          subtitle: org.name,
          routePath: '/o/orgs/${org.id}/pets',
          sortOrder: reason == OrgPetAttentionReason.fosterFinishingSoon ? 10 : 11,
          attentionReason: reason,
        ),
      );
    }

    return tasks;
  }

  Future<List<ShelterTaskItem>> _fosterOnboardingTasks(Organization org) async {
    final people = await ref.watch(orgPeopleProvider(org.id).future);
    return people
        .where((person) => person.fosterNeedsAttention)
        .map(
          (person) => ShelterTaskItem(
            id: 'onboarding-${org.id}-${person.recordId}',
            kind: ShelterTaskKind.fosterOnboarding,
            orgId: org.id,
            orgName: org.name,
            title: person.displayName,
            subtitle: org.name,
            routePath: person.detailPath(org.id),
            sortOrder: 20,
          ),
        )
        .toList(growable: false);
  }

  Future<List<ShelterTaskItem>> _fosterRequestTasks(Organization org) async {
    final requests = await ref.watch(orgFosterRequestsProvider(org.id).future);
    return requests
        .map((request) => _adminFosterRequestTask(org, request))
        .whereType<ShelterTaskItem>()
        .toList(growable: false);
  }

  ShelterTaskItem? _adminFosterRequestTask(
    Organization org,
    FosterRequest request,
  ) {
    if (request.isDraft) {
      return ShelterTaskItem(
        id: 'foster-request-draft-${org.id}-${request.id}',
        kind: ShelterTaskKind.fosterRequestDraft,
        orgId: org.id,
        orgName: org.name,
        title: request.message,
        subtitle: org.name,
        routePath: '/o/orgs/${org.id}/foster-requests/${request.id}',
        sortOrder: 30,
      );
    }

    if (request.isSent && request.responseSummary.pending > 0) {
      return ShelterTaskItem(
        id: 'foster-request-pending-${org.id}-${request.id}',
        kind: ShelterTaskKind.fosterRequestPendingResponses,
        orgId: org.id,
        orgName: org.name,
        title: request.message,
        subtitle: org.name,
        routePath: '/o/orgs/${org.id}/foster-requests/${request.id}',
        sortOrder: 31,
      );
    }

    return null;
  }

  Future<List<ShelterTaskItem>> _fosterRespondTasks(Organization org) async {
    final requests = await ref.watch(orgFosterRequestsProvider(org.id).future);
    return requests
        .where(_fosterNeedsResponse)
        .map(
          (request) => ShelterTaskItem(
            id: 'foster-request-respond-${org.id}-${request.id}',
            kind: ShelterTaskKind.fosterRequestPendingResponses,
            orgId: org.id,
            orgName: org.name,
            title: request.message,
            subtitle: org.name,
            routePath:
                '/o/orgs/${org.id}/foster-requests/${request.id}/respond',
            sortOrder: 15,
          ),
        )
        .toList(growable: false);
  }

  bool _fosterNeedsResponse(FosterRequest request) {
    if (!request.isSent) return false;
    return request.responses.any((response) => response.isPending);
  }
}

final shelterTasksPreviewProvider =
    AsyncNotifierProvider<ShelterTasksPreviewNotifier, ShelterTasksPreviewData>(
      ShelterTasksPreviewNotifier.new,
    );
