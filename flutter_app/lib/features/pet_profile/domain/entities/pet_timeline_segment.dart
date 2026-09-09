import '../../../../core/utils/calendar_date.dart';

/// A segment on a pet's composite timeline (custody, fostering, manual, or gap).
class PetTimelineSegment {
  const PetTimelineSegment({
    required this.kind,
    required this.id,
    required this.startDate,
    this.endDate,
    this.title = '',
    this.description = '',
    this.primaryHolderName,
    this.fosterName,
    this.fillable = false,
    this.milestoneType,
    this.careFamily,
    this.bundleId,
    this.includesFirstCare = false,
  });

  final String kind;
  final String id;
  final String startDate;
  final String? endDate;
  final String title;
  final String description;
  final String? primaryHolderName;
  final String? fosterName;
  final bool fillable;
  final String? milestoneType;
  final String? careFamily;
  final String? bundleId;
  final bool includesFirstCare;

  bool get isGap => kind == 'gap';
  bool get isFosteringSession => kind == 'fostering_session';
  bool get isManual => kind == 'manual';
  bool get isCustody => kind == 'custody';
  bool get isCareMilestone => kind == 'care_milestone';
  bool get isDateOfBirth => kind == 'date_of_birth';
  bool get isJoinedAgatha => kind == 'joined_agatha';

  /// Read-only marker for the pet's date of birth.
  factory PetTimelineSegment.dateOfBirth(DateTime date) {
    return PetTimelineSegment(
      kind: 'date_of_birth',
      id: 'date_of_birth',
      startDate: toCalendarDateString(date)!,
    );
  }

  /// Read-only marker for when the pet joined Agatha Track.
  factory PetTimelineSegment.joinedAgatha({
    required DateTime createdAt,
    String? primaryHolderName,
  }) {
    return PetTimelineSegment(
      kind: 'joined_agatha',
      id: 'joined_agatha',
      startDate: toCalendarDateString(createdAt)!,
      primaryHolderName: primaryHolderName,
    );
  }

  factory PetTimelineSegment.fromJson(Map<String, dynamic> json) {
    return PetTimelineSegment(
      kind: json['kind']?.toString() ?? '',
      id: json['id']?.toString() ?? '',
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      primaryHolderName:
          json['primary_holder_name']?.toString() ??
          json['guardian_name']?.toString(),
      fosterName: json['foster_name']?.toString(),
      fillable: json['fillable'] == true,
      milestoneType: json['milestone_type']?.toString(),
      careFamily: json['care_family']?.toString(),
      bundleId: json['bundle_id']?.toString(),
      includesFirstCare: json['includes_first_care'] == true,
    );
  }
}
