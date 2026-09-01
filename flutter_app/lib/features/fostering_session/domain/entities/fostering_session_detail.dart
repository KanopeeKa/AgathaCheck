import '../../../organization/domain/entities/foster_placement.dart';
import 'session_checklist.dart';
import 'session_viewer_context.dart';

class SessionCounterparty {
  const SessionCounterparty({
    required this.kind,
    this.id,
    this.displayName = '',
    this.email,
  });

  final String kind;
  final String? id;
  final String displayName;
  final String? email;

  factory SessionCounterparty.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SessionCounterparty(kind: 'unknown');
    return SessionCounterparty(
      kind: json['kind']?.toString() ?? 'unknown',
      id: json['id']?.toString(),
      displayName: json['display_name']?.toString() ?? '',
      email: json['email']?.toString(),
    );
  }
}

class SessionPetSummary {
  const SessionPetSummary({
    required this.id,
    this.name = '',
    this.species = '',
  });

  final String id;
  final String name;
  final String species;

  factory SessionPetSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SessionPetSummary(id: '');
    return SessionPetSummary(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      species: json['species']?.toString() ?? '',
    );
  }
}

class SessionOrganizationSummary {
  const SessionOrganizationSummary({required this.id, this.name = ''});

  final String id;
  final String name;

  factory SessionOrganizationSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SessionOrganizationSummary(id: '');
    return SessionOrganizationSummary(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class FosteringSessionDetail {
  const FosteringSessionDetail({
    required this.placement,
    required this.viewer,
    this.pet = const SessionPetSummary(id: ''),
    this.organization = const SessionOrganizationSummary(id: ''),
    this.counterparty = const SessionCounterparty(kind: 'unknown'),
    this.checklist = const SessionChecklist(),
    this.adoption,
    this.documents = const [],
    this.flaggedForAdminReview = false,
  });

  final FosterPlacement placement;
  final SessionViewerContext viewer;
  final SessionPetSummary pet;
  final SessionOrganizationSummary organization;
  final SessionCounterparty counterparty;
  final SessionChecklist checklist;
  final Map<String, dynamic>? adoption;
  final List<dynamic> documents;
  final bool flaggedForAdminReview;

  bool can(String action) => viewer.can(action);

  factory FosteringSessionDetail.fromJson(Map<String, dynamic> json) {
    return FosteringSessionDetail(
      placement: FosterPlacement.fromJson(json),
      viewer: SessionViewerContext.fromJson(
        json['viewer'] as Map<String, dynamic>?,
      ),
      pet: SessionPetSummary.fromJson(json['pet'] as Map<String, dynamic>?),
      organization: SessionOrganizationSummary.fromJson(
        json['organization'] as Map<String, dynamic>?,
      ),
      counterparty: SessionCounterparty.fromJson(
        json['counterparty'] as Map<String, dynamic>?,
      ),
      checklist: SessionChecklist.fromJson(
        json['checklist'] as Map<String, dynamic>?,
      ),
      adoption: json['adoption'] as Map<String, dynamic>?,
      documents: json['documents'] is List
          ? json['documents'] as List
          : const [],
      flaggedForAdminReview: json['flagged_for_admin_review'] == true,
    );
  }

  factory FosteringSessionDetail.fromPlacement(
    FosterPlacement placement, {
    SessionViewerContext? viewer,
    SessionChecklist? checklist,
  }) {
    return FosteringSessionDetail(
      placement: placement,
      viewer:
          viewer ??
          const SessionViewerContext(
            role: SessionViewerRole.shelterOperator,
            allowedActions: [
              SessionAction.transitionReadyToStart,
              SessionAction.updateChecklistItem,
              SessionAction.registerExport,
            ],
          ),
      pet: SessionPetSummary(
        id: placement.petId,
        name: placement.petName,
        species: placement.petSpecies,
      ),
      organization: SessionOrganizationSummary(
        id: placement.organizationId,
        name: placement.organizationName,
      ),
      counterparty: SessionCounterparty(
        kind: 'foster',
        id: placement.fosterUserId,
        displayName: placement.fosterName.isNotEmpty
            ? placement.fosterName
            : placement.fosterEmail,
        email: placement.fosterEmail,
      ),
      checklist: checklist ?? const SessionChecklist(),
    );
  }
}
