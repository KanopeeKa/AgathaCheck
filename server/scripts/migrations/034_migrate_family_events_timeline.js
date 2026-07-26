import { v4 as uuidv4 } from 'uuid';

const CREATE_TABLE_SQL = `
  CREATE TABLE IF NOT EXISTS pet_timeline_entries (
    id UUID PRIMARY KEY,
    pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
    entry_type VARCHAR(16) NOT NULL DEFAULT 'manual',
    title VARCHAR(255) NOT NULL DEFAULT '',
    description TEXT NOT NULL DEFAULT '',
    start_date DATE NOT NULL,
    end_date DATE,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT pet_timeline_entries_type_check CHECK (entry_type IN ('manual'))
  );

  CREATE INDEX IF NOT EXISTS idx_pet_timeline_entries_pet_id
    ON pet_timeline_entries(pet_id, start_date);
`;

const SELECT_SQL = `
  SELECT fe.id,
         fe.pet_id,
         fe.notes,
         fe.from_date,
         fe.to_date,
         fe.created_by,
         fe.created_at
  FROM family_events fe
  WHERE fe.pet_id IS NOT NULL
    AND fe.event_type NOT IN ('placement', 'foster')
    AND NOT EXISTS (
      SELECT 1
      FROM pet_timeline_entries pte
      WHERE pte.pet_id = fe.pet_id
        AND pte.start_date IS NOT DISTINCT FROM fe.from_date
        AND pte.description = COALESCE(fe.notes, '')
    )
`;

const INSERT_SQL = `
  INSERT INTO pet_timeline_entries (
    id, pet_id, entry_type, title, description, start_date, end_date, created_by, created_at
  ) VALUES ($1, $2, 'manual', $3, $4, $5, $6, $7, $8)
`;

/**
 * One-time copy of legacy family_events rows into pet_timeline_entries (D19).
 * Placement/foster rows were handled by migration 016.
 * @param {import('pg').PoolClient} client
 */
export async function migrateFamilyEventsTimeline(client) {
  await client.query(CREATE_TABLE_SQL);
  const { rows } = await client.query(SELECT_SQL);
  for (const row of rows) {
    const startDate = row.from_date;
    if (!startDate) continue;
    const notes = (row.notes || '').trim();
    const title = notes.split('\n')[0].slice(0, 255) || 'Family event';
    await client.query(INSERT_SQL, [
      uuidv4(),
      row.pet_id,
      title,
      notes,
      startDate,
      row.to_date ?? null,
      row.created_by,
      row.created_at,
    ]);
  }
}
