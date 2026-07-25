import '../../../../core/utils/calendar_date.dart';

enum FosterRequestStatus {
  draft,
  sent,
  cancelled;

  static FosterRequestStatus fromWire(String value) {
    switch (value) {
      case 'sent':
        return FosterRequestStatus.sent;
      case 'cancelled':
        return FosterRequestStatus.cancelled;
      case 'draft':
      default:
        return FosterRequestStatus.draft;
    }
  }

  String toWire() => name;
}

enum FosterResponseType {
  pending,
  canHelp,
  cannotHelp;

  static FosterResponseType fromWire(String value) {
    switch (value) {
      case 'can_help':
        return FosterResponseType.canHelp;
      case 'cannot_help':
        return FosterResponseType.cannotHelp;
      case 'pending':
      default:
        return FosterResponseType.pending;
    }
  }

  String toWire() {
    switch (this) {
      case FosterResponseType.canHelp:
        return 'can_help';
      case FosterResponseType.cannotHelp:
        return 'cannot_help';
      case FosterResponseType.pending:
        return 'pending';
    }
  }
}

class FosterRequestResponseSummary {
  const FosterRequestResponseSummary({
    this.pending = 0,
    this.canHelp = 0,
    this.cannotHelp = 0,
  });

  final int pending;
  final int canHelp;
  final int cannotHelp;

  factory FosterRequestResponseSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const FosterRequestResponseSummary();
    return FosterRequestResponseSummary(
      pending: json['pending'] is int
          ? json['pending'] as int
          : int.tryParse(json['pending']?.toString() ?? '') ?? 0,
      canHelp: json['can_help'] is int
          ? json['can_help'] as int
          : int.tryParse(json['can_help']?.toString() ?? '') ?? 0,
      cannotHelp: json['cannot_help'] is int
          ? json['cannot_help'] as int
          : int.tryParse(json['cannot_help']?.toString() ?? '') ?? 0,
    );
  }
}

class FosterRequestPet {
  const FosterRequestPet({
    required this.petId,
    this.petName = '',
    this.species,
  });

  final String petId;
  final String petName;
  final String? species;

  factory FosterRequestPet.fromJson(Map<String, dynamic> json) {
    return FosterRequestPet(
      petId: json['pet_id']?.toString() ?? '',
      petName: json['pet_name']?.toString() ?? '',
      species: json['species']?.toString(),
    );
  }
}

class FosterRequestTarget {
  const FosterRequestTarget({
    required this.orgFosterParentId,
    this.displayName = '',
    this.email,
    this.userId,
    this.approvalState,
    this.optOutAt,
  });

  final String orgFosterParentId;
  final String displayName;
  final String? email;
  final String? userId;
  final String? approvalState;
  final DateTime? optOutAt;

  factory FosterRequestTarget.fromJson(Map<String, dynamic> json) {
    return FosterRequestTarget(
      orgFosterParentId: json['org_foster_parent_id']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      email: json['email']?.toString(),
      userId: json['user_id']?.toString(),
      approvalState: json['approval_state']?.toString(),
      optOutAt: json['opt_out_at'] != null
          ? DateTime.tryParse(json['opt_out_at'].toString())
          : null,
    );
  }
}

class FosterRequestResponse {
  const FosterRequestResponse({
    required this.id,
    required this.orgFosterParentId,
    required this.response,
    this.message = '',
    this.earliestAvailability,
    this.capacityConfirmedAt,
    this.respondedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String orgFosterParentId;
  final FosterResponseType response;
  final String message;
  final DateTime? earliestAvailability;
  final DateTime? capacityConfirmedAt;
  final DateTime? respondedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isPending => response == FosterResponseType.pending;

  factory FosterRequestResponse.fromJson(Map<String, dynamic> json) {
    return FosterRequestResponse(
      id: json['id']?.toString() ?? '',
      orgFosterParentId: json['org_foster_parent_id']?.toString() ?? '',
      response: FosterResponseType.fromWire(
        json['response']?.toString() ?? 'pending',
      ),
      message: json['message']?.toString() ?? '',
      earliestAvailability: parseCalendarDate(json['earliest_availability']),
      capacityConfirmedAt: json['capacity_confirmed_at'] != null
          ? DateTime.tryParse(json['capacity_confirmed_at'].toString())
          : null,
      respondedAt: json['responded_at'] != null
          ? DateTime.tryParse(json['responded_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
}

class FosterRequest {
  const FosterRequest({
    required this.id,
    required this.organizationId,
    required this.message,
    required this.status,
    this.createdBy,
    this.sentAt,
    this.createdAt,
    this.updatedAt,
    this.petIds = const [],
    this.pets = const [],
    this.targets = const [],
    this.responses = const [],
    this.targetCount = 0,
    this.responseSummary = const FosterRequestResponseSummary(),
  });

  final String id;
  final String organizationId;
  final String message;
  final FosterRequestStatus status;
  final String? createdBy;
  final DateTime? sentAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> petIds;
  final List<FosterRequestPet> pets;
  final List<FosterRequestTarget> targets;
  final List<FosterRequestResponse> responses;
  final int targetCount;
  final FosterRequestResponseSummary responseSummary;

  bool get isDraft => status == FosterRequestStatus.draft;
  bool get isSent => status == FosterRequestStatus.sent;

  factory FosterRequest.fromJson(Map<String, dynamic> json) {
    final pets = (json['pets'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((e) => FosterRequestPet.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final petIds = (json['pet_ids'] as List<dynamic>? ?? const [])
        .map((id) => id.toString())
        .where((id) => id.isNotEmpty)
        .toList();

    return FosterRequest(
      id: json['id']?.toString() ?? '',
      organizationId: json['organization_id']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      status: FosterRequestStatus.fromWire(
        json['status']?.toString() ?? 'draft',
      ),
      createdBy: json['created_by']?.toString(),
      sentAt: json['sent_at'] != null
          ? DateTime.tryParse(json['sent_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      petIds: petIds,
      pets: pets,
      targets: (json['targets'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (e) => FosterRequestTarget.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
      responses: (json['responses'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (e) => FosterRequestResponse.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
      targetCount: json['target_count'] is int
          ? json['target_count'] as int
          : int.tryParse(json['target_count']?.toString() ?? '') ?? 0,
      responseSummary: FosterRequestResponseSummary.fromJson(
        json['response_summary'] as Map<String, dynamic>?,
      ),
    );
  }
}
