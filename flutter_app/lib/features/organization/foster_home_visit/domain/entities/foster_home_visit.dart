class FosterHomeVisitAttendee {
  const FosterHomeVisitAttendee({
    required this.id,
    this.userId,
    this.displayName = '',
  });

  final String id;
  final String? userId;
  final String displayName;

  factory FosterHomeVisitAttendee.fromJson(Map<String, dynamic> json) {
    return FosterHomeVisitAttendee(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      displayName: json['display_name']?.toString() ?? '',
    );
  }
}

class FosterHomeVisitChecklistItem {
  const FosterHomeVisitChecklistItem({
    required this.id,
    required this.label,
    this.checked = false,
    this.note = '',
  });

  final String id;
  final String label;
  final bool checked;
  final String note;

  factory FosterHomeVisitChecklistItem.fromJson(Map<String, dynamic> json) {
    return FosterHomeVisitChecklistItem(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      checked: json['checked'] == true,
      note: json['note']?.toString() ?? '',
    );
  }
}

enum FosterHomeVisitStatus {
  scheduled,
  cancelled,
  validated;

  static FosterHomeVisitStatus fromWire(String value) {
    switch (value) {
      case 'cancelled':
        return FosterHomeVisitStatus.cancelled;
      case 'validated':
        return FosterHomeVisitStatus.validated;
      case 'scheduled':
      default:
        return FosterHomeVisitStatus.scheduled;
    }
  }

  String toWire() => name;
}

enum FosterHomeVisitOutcome {
  yes,
  no;

  static FosterHomeVisitOutcome? fromWire(String? value) {
    switch (value?.toLowerCase()) {
      case 'yes':
        return FosterHomeVisitOutcome.yes;
      case 'no':
        return FosterHomeVisitOutcome.no;
      default:
        return null;
    }
  }

  String toWire() => name;
}

class FosterHomeVisit {
  const FosterHomeVisit({
    required this.id,
    required this.organizationId,
    required this.orgFosterParentId,
    required this.status,
    required this.visitDate,
    this.visitTime,
    this.address = '',
    this.notes = '',
    this.checklistItems = const [],
    this.outcome,
    this.outcomeReason = '',
    this.cancelReason = '',
    this.attendees = const [],
    this.validatedAt,
  });

  final String id;
  final String organizationId;
  final String orgFosterParentId;
  final FosterHomeVisitStatus status;
  final String visitDate;
  final String? visitTime;
  final String address;
  final String notes;
  final List<FosterHomeVisitChecklistItem> checklistItems;
  final FosterHomeVisitOutcome? outcome;
  final String outcomeReason;
  final String cancelReason;
  final List<FosterHomeVisitAttendee> attendees;
  final String? validatedAt;

  bool get isScheduled => status == FosterHomeVisitStatus.scheduled;

  factory FosterHomeVisit.fromJson(Map<String, dynamic> json) {
    final checklistRaw = json['checklist_items'];
    return FosterHomeVisit(
      id: json['id']?.toString() ?? '',
      organizationId: json['organization_id']?.toString() ?? '',
      orgFosterParentId: json['org_foster_parent_id']?.toString() ?? '',
      status: FosterHomeVisitStatus.fromWire(json['status']?.toString() ?? ''),
      visitDate: json['visit_date']?.toString() ?? '',
      visitTime: json['visit_time']?.toString(),
      address: json['address']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      checklistItems: checklistRaw is List
          ? checklistRaw
                .whereType<Map>()
                .map(
                  (item) => FosterHomeVisitChecklistItem.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      outcome: FosterHomeVisitOutcome.fromWire(json['outcome']?.toString()),
      outcomeReason: json['outcome_reason']?.toString() ?? '',
      cancelReason: json['cancel_reason']?.toString() ?? '',
      attendees: (json['attendees'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => FosterHomeVisitAttendee.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      validatedAt: json['validated_at']?.toString(),
    );
  }
}

class FosterHomeVisitStatusSnapshot {
  const FosterHomeVisitStatusSnapshot({
    this.activeVisit,
    this.latestValidated,
  });

  final FosterHomeVisit? activeVisit;
  final FosterHomeVisit? latestValidated;

  factory FosterHomeVisitStatusSnapshot.fromJson(Map<String, dynamic> json) {
    final active = json['active_visit'];
    final latest = json['latest_validated'];
    return FosterHomeVisitStatusSnapshot(
      activeVisit: active is Map
          ? FosterHomeVisit.fromJson(Map<String, dynamic>.from(active))
          : null,
      latestValidated: latest is Map
          ? FosterHomeVisit.fromJson(Map<String, dynamic>.from(latest))
          : null,
    );
  }
}
