/**
 * DC-6 / D5: list care items with DATE fields touched since a cutoff (manual review).
 *
 * @param {import('pg').Pool} pool
 * @param {{ updatedSinceIso?: string }} [options]
 */
export async function reportD5DateEdits(pool, { updatedSinceIso = '2026-10-01' } = {}) {
  const result = await pool.query(
    `SELECT id, name, pet_id,
       to_char(schedule_anchor_date, 'YYYY-MM-DD') AS schedule_anchor_date,
       to_char(next_due_date, 'YYYY-MM-DD') AS next_due_date,
       to_char(series_resumed_on, 'YYYY-MM-DD') AS series_resumed_on,
       to_char(paused_until, 'YYYY-MM-DD') AS paused_until,
       updated_at
     FROM health_entries
     WHERE updated_at >= $1::timestamptz
     ORDER BY updated_at DESC`,
    [`${updatedSinceIso}T00:00:00Z`],
  );
  return result.rows;
}
