import '../../domain/entities/care_safeguard.dart';

class CareSafeguardModel {
  const CareSafeguardModel({
    required this.id,
    required this.petId,
    required this.safeguardType,
    required this.safeguardKey,
    required this.status,
    required this.policyVersion,
    required this.copyKey,
    required this.evidence,
    this.dismissedAt,
  });

  final String id;
  final String petId;
  final String safeguardType;
  final String safeguardKey;
  final String status;
  final String policyVersion;
  final String copyKey;
  final Map<String, dynamic> evidence;
  final DateTime? dismissedAt;

  factory CareSafeguardModel.fromJson(Map<String, dynamic> json) {
    return CareSafeguardModel(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      safeguardType: json['safeguard_type'] as String,
      safeguardKey: json['safeguard_key'] as String,
      status: json['status'] as String,
      policyVersion: json['policy_version'] as String,
      copyKey: json['copy_key'] as String,
      evidence: Map<String, dynamic>.from(json['evidence'] as Map? ?? {}),
      dismissedAt: json['dismissed_at'] != null
          ? DateTime.tryParse(json['dismissed_at'] as String)
          : null,
    );
  }

  CareSafeguard toEntity() {
    return CareSafeguard(
      id: id,
      petId: petId,
      safeguardType: safeguardType,
      safeguardKey: safeguardKey,
      status: status,
      policyVersion: policyVersion,
      copyKey: copyKey,
      evidence: evidence,
      dismissedAt: dismissedAt,
    );
  }
}
