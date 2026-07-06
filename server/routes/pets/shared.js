import jwt from 'jsonwebtoken';

import { JWT_SECRET } from '../../config/jwtSecret.js';
import { dateToIsoDate } from '../../lib/calendarDate.js';

export const FOSTER_PLACEMENT_SELECT_SQL = `
  (SELECT fp.status
   FROM foster_placements fp
   WHERE fp.pet_id = p.id
     AND fp.status = ANY($4::text[])
   ORDER BY fp.created_at DESC
   LIMIT 1) AS foster_placement_status,
  (SELECT NULLIF(TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')), '')
   FROM foster_placements fp
   LEFT JOIN users u ON u.id = fp.foster_user_id
   WHERE fp.pet_id = p.id
     AND fp.status = ANY($4::text[])
   ORDER BY fp.created_at DESC
   LIMIT 1) AS foster_name`;

export const PET_COLOR_PALETTE = [
  0xFF7E57C2, 0xFF9575CD, 0xFF5C6BC0, 0xFF7986CB, 0xFF4DB6AC,
  0xFF81C784, 0xFF4FC3F7, 0xFFBA68C8, 0xFFF06292, 0xFFE57373,
  0xFFFFB74D, 0xFFA1887F, 0xFF90A4AE, 0xFF64B5F6, 0xFFAED581,
];

export function extractUserId(req) {
  const auth = req.headers['authorization'] || req.headers['Authorization'];
  if (!auth || !auth.startsWith('Bearer ')) return null;
  try {
    return jwt.verify(auth.substring(7), JWT_SECRET).id;
  } catch (_) {
    return null;
  }
}

export function resolveColorValue(raw) {
  if (raw == null) return null;
  const v = typeof raw === 'number' ? raw : parseInt(raw, 10);
  if (isNaN(v)) return null;
  if (v < PET_COLOR_PALETTE.length) return PET_COLOR_PALETTE[v];
  return v;
}

export function petRowToMap(row) {
  const isShared = row.is_shared === true || row.is_shared === 't';
  const isFoster = row.is_foster === true || row.is_foster === 't';
  return {
    id: row.id,
    user_id: row.user_id,
    name: row.name,
    species: row.species,
    breed: row.breed || '',
    age: row.age,
    dateOfBirth: row.date_of_birth ? dateToIsoDate(row.date_of_birth) : null,
    date_of_birth: row.date_of_birth ? dateToIsoDate(row.date_of_birth) : null,
    weight: row.weight,
    gender: row.gender,
    bio: row.bio || '',
    insurance: row.insurance || '',
    neuteredDate: row.neutered_date ? dateToIsoDate(row.neutered_date) : null,
    neuterDismissed: row.neuter_dismissed || false,
    chipId: row.chip_id || '',
    chipDismissed: row.chip_dismissed || false,
    photoPath: row.photo_path,
    vetId: row.vet_id ? String(row.vet_id) : null,
    colorValue: resolveColorValue(row.color_index),
    passedAway: row.passed_away || false,
    // Shared pets follow the owner's org in the DB, but the viewer should see
    // them under "My Pets", not the owner's organisation section.
    organization_id: isShared ? null : row.organization_id,
    organization_name: isShared ? null : (row.organization_name || null),
    is_shared: isShared,
    is_foster: isFoster,
    foster_placement_status: row.foster_placement_status || null,
    foster_name: row.foster_name || null,
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

export async function autoAssignColors(pool, pets) {
  const usedColors = new Set();
  for (const p of pets) {
    if (p.colorValue != null) usedColors.add(p.colorValue);
  }
  for (const p of pets) {
    if (p.colorValue == null) {
      let color = PET_COLOR_PALETTE[0];
      for (const c of PET_COLOR_PALETTE) {
        if (!usedColors.has(c)) {
          color = c;
          break;
        }
      }
      usedColors.add(color);
      p.colorValue = color;
      try {
        await pool.query('UPDATE pets SET color_index = $1 WHERE id = $2', [color, p.id]);
      } catch (_) {}
    }
  }
}

export async function userInOrg(pool, orgId, userId) {
  const result = await pool.query(
    'SELECT 1 FROM organization_users WHERE organization_id = $1 AND user_id = $2 LIMIT 1',
    [orgId, userId]
  );
  return result.rows.length > 0;
}

export async function withOptionalTransaction(pool, fn) {
  if (typeof pool.connect === 'function') {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const result = await fn(client);
      await client.query('COMMIT');
      return result;
    } catch (err) {
      try {
        await client.query('ROLLBACK');
      } catch (_) {
        /* ignore */
      }
      throw err;
    } finally {
      client.release();
    }
  }
  return fn(pool);
}
