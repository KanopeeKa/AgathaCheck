/// A segment on a pet's composite timeline (custody, fostering, manual, or gap).
class PetTimelineSegment {
  const PetTimelineSegment({
    required this.kind,
    required this.id,
    required this.startDate,
    this.endDate,
    this.title = '',
    this.description = '',
    this.guardianName,
    this.fosterName,
    this.fillable = false,
  });

  final String kind;
  final String id;
  final String startDate;
  final String? endDate;
  final String title;
  final String description;
  final String? guardianName;
  final String? fosterName;
  final bool fillable;

  bool get isGap => kind == 'gap';
  bool get isFosteringSession => kind == 'fostering_session';
  bool get isManual => kind == 'manual';
  bool get isCustody => kind == 'custody';

  factory PetTimelineSegment.fromJson(Map<String, dynamic> json) {
    return PetTimelineSegment(
      kind: json['kind']?.toString() ?? '',
      id: json['id']?.toString() ?? '',
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      guardianName: json['guardian_name']?.toString(),
      fosterName: json['foster_name']?.toString(),
      fillable: json['fillable'] == true,
    );
  }
}
