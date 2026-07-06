import 'package:postgres/postgres.dart';

import 'calendar_date.dart';

const placementStatusPending = 'pending';
const placementStatusInProgress = 'in_progress';
const placementStatusNotInFoster = 'not_in_foster';
const placementStatusWaitingAdoption = 'waiting_adoption_confirmation';
const placementStatusPendingConditions = 'pending_adoption_conditions';
const placementStatusAdopted = 'adopted';

const openPlacementStatuses = [
  placementStatusPending,
  placementStatusInProgress,
  placementStatusWaitingAdoption,
  placementStatusPendingConditions,
];

const fosterActiveStatuses = [
  placementStatusInProgress,
  placementStatusWaitingAdoption,
  placementStatusPendingConditions,
];

const fosterPetAccessRole = 'foster';

String openPlacementStatusesSql() =>
    openPlacementStatuses.map((s) => "'$s'").join(', ');

String fosterActiveStatusesSql() =>
    fosterActiveStatuses.map((s) => "'$s'").join(', ');

Map<String, dynamic> placementToMap(
  Map<String, dynamic> row, {
  Map<String, dynamic> extras = const {},
}) {
  return {
    'id': row['id']?.toString(),
    'organization_id': row['organization_id']?.toString(),
    'pet_id': row['pet_id']?.toString(),
    'foster_user_id': row['foster_user_id']?.toString(),
    'org_foster_parent_id': row['org_foster_parent_id']?.toString(),
    'status': row['status'],
    'start_date': dateToIsoDate(row['start_date']),
    'end_date': dateToIsoDate(row['end_date']),
    'notes': row['notes']?.toString() ?? '',
    'adoption_conditions': row['adoption_conditions']?.toString() ?? '',
    'created_by': row['created_by']?.toString(),
    'created_at': row['created_at']?.toString(),
    'updated_at': row['updated_at']?.toString(),
    'responded_at': row['responded_at']?.toString(),
    'pet_name': extras['pet_name'] ?? row['pet_name'],
    'pet_species': extras['pet_species'] ?? row['pet_species'],
    'organization_name': extras['organization_name'] ?? row['organization_name'],
    'foster_name': extras['foster_name'] ?? row['foster_name'],
    'foster_email': extras['foster_email'] ?? row['foster_email'],
  };
}

Map<String, dynamic> _rowToMap(ResultRow row) =>
    row.toColumnMap().map((k, v) => MapEntry(k, v));

Future<Map<String, dynamic>?> getActivePlacementForPet(
  Pool pool,
  String petId,
) async {
  final results = await pool.execute(
    Sql('''
      SELECT fp.*
      FROM foster_placements fp
      WHERE fp.pet_id = @petId
        AND fp.status IN ($openPlacementStatusesSql())
      ORDER BY fp.created_at DESC
      LIMIT 1
    '''),
    parameters: {'petId': petId},
  );
  if (results.isEmpty) return null;
  return _rowToMap(results.first);
}

Future<void> revokeFosterPetAccess(
  Pool pool,
  String petId,
  String userId,
) async {
  await pool.execute(
    Sql.named('''
      DELETE FROM pet_access
      WHERE pet_id = @petId AND user_id = @userId AND role = @role
    '''),
    parameters: {
      'petId': petId,
      'userId': userId,
      'role': fosterPetAccessRole,
    },
  );
}

Future<Map<String, dynamic>> cancelAdoptionPlacement(
  Pool pool,
  Map<String, dynamic> placement, {
  String? endDate,
}) async {
  final results = await pool.execute(
    Sql.named('''
      UPDATE foster_placements
      SET status = @status,
          end_date = COALESCE(@endDate::date, CURRENT_DATE),
          adoption_conditions = '',
          updated_at = NOW()
      WHERE id = @id
      RETURNING *
    '''),
    parameters: {
      'status': placementStatusNotInFoster,
      'endDate': endDate,
      'id': placement['id'],
    },
  );
  await revokeFosterPetAccess(
    pool,
    placement['pet_id'].toString(),
    placement['foster_user_id'].toString(),
  );
  return _rowToMap(results.first);
}

Future<Map<String, dynamic>?> loadPlacementDetail(
  Pool pool,
  String placementId,
) async {
  final results = await pool.execute(
    Sql.named('''
      SELECT fp.*,
             p.name AS pet_name,
             p.species AS pet_species,
             o.name AS organization_name,
             TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS foster_name,
             u.email AS foster_email
      FROM foster_placements fp
      JOIN pets p ON p.id = fp.pet_id
      JOIN organizations o ON o.id = fp.organization_id
      JOIN users u ON u.id = fp.foster_user_id
      WHERE fp.id = @placementId
    '''),
    parameters: {'placementId': placementId},
  );
  if (results.isEmpty) return null;
  return _rowToMap(results.first);
}
