import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_color_tokens.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../experience/presentation/widgets/pet_care_dashboard_section_header.dart';
import '../../../../experience/presentation/widgets/pet_care_illustrated_empty_state.dart';
import '../../../../experience/presentation/widgets/pet_care_operations_desk_layout.dart';
import '../../providers/org_provider_invites.dart';
import '../../providers/shelter_tasks_provider.dart';
import '../../utils/org_pets_care_utils.dart';
import '../organization_role_labels.dart';
import 'shelter_task_item.dart';
import 'shelter_task_row.dart';

class ShelterTasksPreview extends ConsumerWidget {
  const ShelterTasksPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final tasksAsync = ref.watch(shelterTasksPreviewProvider);

    return Column(
      key: const Key('shelter_tasks_preview'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PetCareDashboardSectionHeader(
          title: l.shelterTasksEyebrowLabel,
          titleColor: AppColorTokens.organizationPrimary,
        ),
        const SizedBox(height: 10),
        tasksAsync.when(
          loading: () => const PetCareDeskSectionCard(
            tint: AppColorTokens.surface,
            child: SizedBox(
              height: 56,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (data) => PetCareDeskSectionCard(
            key: const Key('shelter_tasks_card'),
            tint: AppColorTokens.surface,
            child: data.isEmpty
                ? PetCareIllustratedEmptyState(
                    key: const Key('shelter_tasks_empty'),
                    title: l.guardianEmptyCareClearTitle,
                    body: l.homeNoDueEvents,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final task in data.previewTasks)
                        ShelterTaskRow(task: task, l: l),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

/// Inline accept/decline actions for pending org invites inside the tasks block.
class ShelterTaskInviteActions extends ConsumerWidget {
  const ShelterTaskInviteActions({
    super.key,
    required this.invite,
    required this.l,
  });

  final PendingOrgInvite invite;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          key: Key('shelter_task_decline_${invite.id}'),
          onPressed: () => _decline(context, ref),
          child: Text(l.declineInvite),
        ),
        const SizedBox(width: 8),
        FilledButton(
          key: Key('shelter_task_accept_${invite.id}'),
          onPressed: () => _accept(context, ref),
          child: Text(l.acceptInvite),
        ),
      ],
    );
  }

  Future<void> _decline(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(pendingOrgInvitesProvider.notifier)
          .declineInvite(invite.id);
      ref.invalidate(shelterTasksPreviewProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.inviteDeclined)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    try {
      final orgId = await ref
          .read(pendingOrgInvitesProvider.notifier)
          .acceptInvite(invite.id);
      ref.invalidate(shelterTasksPreviewProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.inviteAccepted)));
        context.push('/o/orgs/$orgId');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}

String shelterTaskTitle(AppLocalizations l, ShelterTaskItem task) {
  return switch (task.kind) {
    ShelterTaskKind.pendingInvite => l.inviteToJoinOrg(task.orgName),
    ShelterTaskKind.petNeedAttention => task.title,
    ShelterTaskKind.fosterOnboarding => task.title,
    ShelterTaskKind.fosterRequestDraft => l.fosterRequestStatusDraft,
    ShelterTaskKind.fosterRequestPendingResponses =>
      l.fosterRequestRespondTitle,
  };
}

String? shelterTaskSubtitle(AppLocalizations l, ShelterTaskItem task) {
  return switch (task.kind) {
    ShelterTaskKind.pendingInvite => l.inviteAsRole(
      localizedOrgRoleWire(l, task.invite?.desiredRole ?? 'member'),
    ),
    ShelterTaskKind.petNeedAttention when task.attentionReason != null =>
      '${task.orgName} · ${localizedAttentionReason(l, task.attentionReason!)}',
    ShelterTaskKind.petNeedAttention => task.orgName,
    ShelterTaskKind.fosterOnboarding =>
      '${task.orgName} · ${l.orgFosterBadgeNeedsAttention}',
    ShelterTaskKind.fosterRequestDraft ||
    ShelterTaskKind.fosterRequestPendingResponses => task.orgName,
  };
}

String localizedAttentionReason(
  AppLocalizations l,
  OrgPetAttentionReason reason,
) {
  return switch (reason) {
    OrgPetAttentionReason.notInFoster => l.orgPetsNeedAttentionNotInFoster,
    OrgPetAttentionReason.fosterFinishingSoon =>
      l.orgPetsNeedAttentionFosterFinishingSoon,
  };
}
