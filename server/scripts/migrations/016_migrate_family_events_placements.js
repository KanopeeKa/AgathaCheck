import { v4 as uuidv4 } from 'uuid';

const SELECT_SQL = `
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
`;

const INSERT_SQL = `
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
  ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
`;

/**
 * Migrate legacy family_events placement rows into foster_placements.
 * @param {import('pg').PoolClient} client
 */
export async function migrateFamilyEventsPlacements(client) {
  const { rows } = await client.query(SELECT_SQL);
  for (const row of rows) {
    const notes = `${(row.notes || '').trim()} [migrated from family_events]`.trim();
    await client.query(INSERT_SQL, [
      uuidv4(),
      row.organization_id,
      row.pet_id,
      row.assigned_to_user_id,
      'not_in_foster',
      row.from_date,
      row.to_date ?? row.from_date,
      notes,
      row.created_by,
      row.created_at,
      row.updated_at ?? row.created_at,
    ]);
  }
}
