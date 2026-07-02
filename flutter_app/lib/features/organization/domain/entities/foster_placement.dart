import '../../../../core/utils/calendar_date.dart';

class FosterPlacement {
  const FosterPlacement({
    required this.id,
    required this.organizationId,
    required this.petId,
    required this.fosterUserId,
    required this.status,
    this.petName = '',
    this.petSpecies = '',
    this.organizationName = '',
    this.fosterName = '',
    this.fosterEmail = '',
    this.startDate,
    this.endDate,
    this.notes = '',
    this.createdBy,
    this.createdAt,
    this.respondedAt,
  });

  final String id;
  final String organizationId;
  final String petId;
  final String fosterUserId;
  final String status;
  final String petName;
  final String petSpecies;
  final String organizationName;
  final String fosterName;
  final String fosterEmail;
  final DateTime? startDate;
  final DateTime? endDate;
  final String notes;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? respondedAt;

  bool get isPending => status == 'pending';
  bool get isInProgress => status == 'in_progress';
  bool get isNotInFoster => status == 'not_in_foster';
  bool get isActive => isPending || isInProgress;

  factory FosterPlacement.fromJson(Map<String, dynamic> json) {
    return FosterPlacement(
      id: json['id']?.toString() ?? '',
      organizationId: json['organization_id']?.toString() ?? '',
      petId: json['pet_id']?.toString() ?? '',
      fosterUserId: json['foster_user_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'not_in_foster',
      petName: json['pet_name']?.toString() ?? '',
      petSpecies: json['pet_species']?.toString() ?? '',
      organizationName: json['organization_name']?.toString() ?? '',
      fosterName: json['foster_name']?.toString() ?? '',
      fosterEmail: json['foster_email']?.toString() ?? '',
      startDate: parseCalendarDate(json['start_date']),
      endDate: parseCalendarDate(json['end_date']),
      notes: json['notes']?.toString() ?? '',
      createdBy: json['created_by']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      respondedAt: json['responded_at'] != null
          ? DateTime.tryParse(json['responded_at'].toString())
          : null,
    );
  }
}

class PetFosterPlacementState {
  const PetFosterPlacementState({
    required this.status,
    this.placement,
  });

  final String status;
  final FosterPlacement? placement;

  bool get isNotInFoster =>
      status == 'not_in_foster' || placement == null || !placement!.isActive;

  factory PetFosterPlacementState.fromJson(Map<String, dynamic> json) {
    final placementJson = json['placement'];
    return PetFosterPlacementState(
      status: json['status']?.toString() ?? 'not_in_foster',
      placement: placementJson is Map<String, dynamic>
          ? FosterPlacement.fromJson(placementJson)
          : null,
    );
  }
}
