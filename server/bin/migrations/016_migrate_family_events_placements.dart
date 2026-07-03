import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';

final _uuid = Uuid();

const _selectSql = '''
  SELECT fe.organization_id,
         fe.pet_id,
         fe.assigned_to_user_id,
         fe.from_date,
         fe.to_date,
         fe.notes,
         fe.created_by,
         fe.created_at,
         fe.updated_at
  FROM family_events fe
  WHERE fe.pet_id IS NOT NULL
    AND fe.organization_id IS NOT NULL
    AND fe.assigned_to_user_id IS NOT NULL
    AND fe.event_type IN ('placement', 'foster')
    AND NOT EXISTS (
      SELECT 1
      FROM foster_placements fp
      WHERE fp.pet_id = fe.pet_id
        AND fp.foster_user_id = fe.assigned_to_user_id
        AND fp.start_date IS NOT DISTINCT FROM fe.from_date
    )
''';

const _insertSql = '''
  INSERT INTO foster_placements (
    id,
    organization_id,
    pet_id,
    foster_user_id,
    status,
    start_date,
    end_date,
    notes,
    created_by,
    created_at,
    updated_at
  ) VALUES (
    @id, @organizationId, @petId, @fosterUserId, @status,
    @startDate, @endDate, @notes, @createdBy, @createdAt, @updatedAt
  )
''';

Future<void> migrateFamilyEventsPlacements(Pool pool) async {
  final rows = await pool.execute(Sql(_selectSql));
  for (final row in rows) {
    final notesRaw = row[5]?.toString() ?? '';
    final notes = '$notesRaw [migrated from family_events]'.trim();
    final fromDate = row[3];
    final toDate = row[4] ?? fromDate;
    final createdAt = row[8];
    await pool.execute(
      Sql.named(_insertSql),
      parameters: {
        'id': _uuid.v4(),
        'organizationId': row[0],
        'petId': row[1],
        'fosterUserId': row[2],
        'status': 'not_in_foster',
        'startDate': fromDate,
        'endDate': toDate,
        'notes': notes,
        'createdBy': row[6],
        'createdAt': createdAt,
        'updatedAt': row[9] ?? createdAt,
      },
    );
  }
}
