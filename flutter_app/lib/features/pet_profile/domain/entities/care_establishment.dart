import '../../domain/entities/care_family.dart';

/// Server-authoritative care maturity record for one rhythm (CP-5 read model).
class CareEstablishment {
  const CareEstablishment({
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
}
