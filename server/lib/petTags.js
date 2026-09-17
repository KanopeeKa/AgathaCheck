import { v4 as uuidv4 } from 'uuid';

import { userCanAccessPet } from './petAccess.js';

export const TAG_NAME_MAX_LENGTH = 64;

/**
 * @param {string} name
 * @returns {string}
 */
export function normalizeTagName(name) {
  if (typeof name !== 'string') {
    throw new TagValidationError('name must be a string');
  }
  const trimmed = name.trim();
  if (!trimmed) {
    throw new TagValidationError('name is required');
  }
  if (trimmed.length > TAG_NAME_MAX_LENGTH) {
    throw new TagValidationError(`name must be at most ${TAG_NAME_MAX_LENGTH} characters`);
  }
  return trimmed;
}

export class TagValidationError extends Error {
  constructor(message) {
    super(message);
    this.name = 'TagValidationError';
  }
}

export class TagNotFoundError extends Error {
  constructor(message = 'Tag not found') {
    super(message);
    this.name = 'TagNotFoundError';
  }
}

export class TagNameConflictError extends Error {
  constructor(message = 'Tag name already exists') {
    super(message);
    this.name = 'TagNameConflictError';
  }
}

/**
 * @param {import('pg').Pool | import('pg').PoolClient} pool
 * @param {string} userId
 * @param {string} name
 * @param {string} [excludeTagId]
 */
export async function tagNameExistsForUser(pool, userId, name, excludeTagId = null) {
  const params = [userId, name.toLowerCase()];
  let sql = `SELECT 1 FROM pet_tags
             WHERE user_id = $1 AND lower(name) = $2`;
  if (excludeTagId) {
    params.push(excludeTagId);
    sql += ' AND id != $3';
  }
  sql += ' LIMIT 1';
  const result = await pool.query(sql, params);
  return result.rows.length > 0;
}

/**
 * @param {object} row
 */
export function tagRowToMap(row) {
  return {
    id: row.id,
    name: row.name,
    pet_ids: Array.isArray(row.pet_ids) ? row.pet_ids : [],
    created_at: row.created_at?.toISOString?.() || row.created_at,
    updated_at: row.updated_at?.toISOString?.() || row.updated_at,
  };
}

/**
 * @param {import('pg').Pool | import('pg').PoolClient} pool
 * @param {string} userId
 */
export async function listUserTagsWithPetIds(pool, userId) {
  const result = await pool.query(
    `SELECT pt.id, pt.name, pt.created_at, pt.updated_at,
            COALESCE(
              array_agg(pta.pet_id ORDER BY pta.created_at) FILTER (WHERE pta.pet_id IS NOT NULL),
              '{}'
            ) AS pet_ids
     FROM pet_tags pt
     LEFT JOIN pet_tag_assignments pta ON pta.pet_tag_id = pt.id
     WHERE pt.user_id = $1
     GROUP BY pt.id
     ORDER BY lower(pt.name) ASC`,
    [userId]
  );
  return result.rows.map(tagRowToMap);
}

/**
 * @param {import('pg').Pool | import('pg').PoolClient} pool
 * @param {string} userId
 * @param {string} name
 */
export async function createTag(pool, userId, name) {
  const normalized = normalizeTagName(name);
  if (await tagNameExistsForUser(pool, userId, normalized)) {
    throw new TagNameConflictError();
  }
  const id = uuidv4();
  const result = await pool.query(
    `INSERT INTO pet_tags (id, user_id, name)
     VALUES ($1, $2, $3)
     RETURNING id, name, created_at, updated_at`,
    [id, userId, normalized]
  );
  return tagRowToMap({ ...result.rows[0], pet_ids: [] });
}

/**
 * @param {import('pg').Pool | import('pg').PoolClient} pool
 * @param {string} userId
 * @param {string} tagId
 * @param {string} name
 */
export async function renameTag(pool, userId, tagId, name) {
  const normalized = normalizeTagName(name);
  const owned = await pool.query(
    'SELECT id FROM pet_tags WHERE id = $1 AND user_id = $2 LIMIT 1',
    [tagId, userId]
  );
  if (owned.rows.length === 0) {
    throw new TagNotFoundError();
  }
  if (await tagNameExistsForUser(pool, userId, normalized, tagId)) {
    throw new TagNameConflictError();
  }
  await pool.query(
    `UPDATE pet_tags SET name = $1, updated_at = NOW()
     WHERE id = $2 AND user_id = $3`,
    [normalized, tagId, userId]
  );
  const tags = await listUserTagsWithPetIds(pool, userId);
  const updated = tags.find((tag) => tag.id === tagId);
  if (!updated) throw new TagNotFoundError();
  return updated;
}

/**
 * @param {import('pg').Pool | import('pg').PoolClient} pool
 * @param {string} userId
 * @param {string} tagId
 */
export async function deleteTag(pool, userId, tagId) {
  const result = await pool.query(
    'DELETE FROM pet_tags WHERE id = $1 AND user_id = $2 RETURNING id',
    [tagId, userId]
  );
  if (result.rows.length === 0) {
    throw new TagNotFoundError();
  }
}

/**
 * @param {import('pg').Pool | import('pg').PoolClient} pool
 * @param {string} userId
 * @param {string} petId
 * @param {string} tagId
 */
export async function assignTagToPet(pool, userId, petId, tagId) {
  if (!(await userCanAccessPet(pool, petId, userId))) {
    throw new TagNotFoundError('Pet not found');
  }
  const owned = await pool.query(
    'SELECT id FROM pet_tags WHERE id = $1 AND user_id = $2 LIMIT 1',
    [tagId, userId]
  );
  if (owned.rows.length === 0) {
    throw new TagNotFoundError();
  }
  await pool.query(
    `INSERT INTO pet_tag_assignments (pet_tag_id, pet_id)
     VALUES ($1, $2)
     ON CONFLICT (pet_tag_id, pet_id) DO NOTHING`,
    [tagId, petId]
  );
}

/**
 * @param {import('pg').Pool | import('pg').PoolClient} pool
 * @param {string} userId
 * @param {string} petId
 * @param {string} tagId
 */
export async function unassignTagFromPet(pool, userId, petId, tagId) {
  if (!(await userCanAccessPet(pool, petId, userId))) {
    throw new TagNotFoundError('Pet not found');
  }
  const owned = await pool.query(
    'SELECT id FROM pet_tags WHERE id = $1 AND user_id = $2 LIMIT 1',
    [tagId, userId]
  );
  if (owned.rows.length === 0) {
    throw new TagNotFoundError();
  }
  await pool.query(
    `DELETE FROM pet_tag_assignments
     WHERE pet_tag_id = $1 AND pet_id = $2`,
    [tagId, petId]
  );
}
