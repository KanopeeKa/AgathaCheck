import '../../providers/org_provider_invites.dart';
import '../../utils/org_pets_care_utils.dart';

/// Cross-org actionable item shown in the Shelter dashboard tasks preview.
enum ShelterTaskKind {
  pendingInvite,
  petNeedAttention,
  fosterOnboarding,
  fosterRequestDraft,
  fosterRequestPendingResponses,
}

class ShelterTaskItem {
  const ShelterTaskItem({
    required this.id,
    required this.kind,
    required this.orgId,
    required this.orgName,
    required this.title,
    this.subtitle,
    required this.routePath,
    this.sortOrder = 0,
    this.invite,
    this.attentionReason,
  });

  final String id;
  final ShelterTaskKind kind;
  final String orgId;
  final String orgName;
  final String title;
  final String? subtitle;
  final String routePath;
  final int sortOrder;
  final PendingOrgInvite? invite;
  final OrgPetAttentionReason? attentionReason;

  bool get isPendingInvite => kind == ShelterTaskKind.pendingInvite;
}

class ShelterTasksPreviewData {
  const ShelterTasksPreviewData({
    required this.previewTasks,
    required this.totalTaskCount,
  });

  final List<ShelterTaskItem> previewTasks;
  final int totalTaskCount;

  bool get isEmpty => totalTaskCount == 0;
}
