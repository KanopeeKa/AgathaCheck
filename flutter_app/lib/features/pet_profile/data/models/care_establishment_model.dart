import '../../domain/entities/care_establishment.dart';
import '../../domain/entities/care_family.dart';

class CareEstablishmentModel {
  const CareEstablishmentModel({
    required this.id,
    required this.careFamily,
    required this.healthEntryId,
    required this.establishedAt,
    required this.policyVersion,
  });

  final String id;
  final CareFamily careFamily;
  final String healthEntryId;
  final DateTime establishedAt;
  final String policyVersion;

  factory CareEstablishmentModel.fromJson(Map<String, dynamic> json) {
    final family = CareFamilyWire.fromWire(json['care_family'] as String?);
    if (family == null) {
      throw FormatException('Unknown care_family: ${json['care_family']}');
    }
    final establishedRaw = json['established_at'] as String?;
    final establishedAt = establishedRaw != null
        ? DateTime.tryParse(establishedRaw)
        : null;
    if (establishedAt == null) {
      throw FormatException('Missing established_at');
    }
    return CareEstablishmentModel(
      id: json['id'] as String,
      careFamily: family,
      healthEntryId: json['health_entry_id'] as String,
      establishedAt: establishedAt,
      policyVersion: json['policy_version'] as String,
    );
  }

  CareEstablishment toEntity() => CareEstablishment(
    id: id,
    careFamily: careFamily,
    healthEntryId: healthEntryId,
    establishedAt: establishedAt,
    policyVersion: policyVersion,
  );
}
