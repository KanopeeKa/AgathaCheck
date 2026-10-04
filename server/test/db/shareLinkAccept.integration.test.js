import { randomUUID } from 'crypto';

import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';

import { acceptLink, createLink } from '../../services/sharing/shareLinkService.js';
import { createDbPool } from './helpers/careHarness.js';

let pool;
let dbAvailable = false;

beforeAll(async () => {
  pool = createDbPool();
  try {
    await pool.query('SELECT 1 FROM pet_share_links LIMIT 1');
    dbAvailable = true;
  } catch {
    dbAvailable = false;
    await pool.end();
    pool = null;
  }
}, 30000);

afterAll(async () => {
  await pool?.end();
});

describe('share link accept (real PG)', () => {
  it('creates a single pet_access row when accept races', async () => {
    if (!dbAvailable || !pool) return;

    const ownerId = randomUUID();
    const accepterId = randomUUID();
    const petId = randomUUID();

    await pool.query(
      `INSERT INTO users (id, email, password_hash, first_name, last_name)
       VALUES ($1, $2, 'hash', 'Owner', 'One'), ($3, $4, 'hash', 'Accepter', 'Two')`,
      [ownerId, `owner-${ownerId}@example.com`, accepterId, `accepter-${accepterId}@example.com`],
    );
    await pool.query(
      `INSERT INTO pets (id, user_id, name, species) VALUES ($1, $2, 'Buddy', 'dog')`,
      [petId, ownerId],
    );

    const link = await createLink(pool, { userId: ownerId, petId });
    expect(link.status).toBe(201);

    const [a, b] = await Promise.all([
      acceptLink(pool, { userId: accepterId, code: link.share_code }),
      acceptLink(pool, { userId: accepterId, code: link.share_code }),
    ]);

    expect(a.pet_id || a.error).toBeTruthy();
    expect(b.pet_id || b.error).toBeTruthy();

    const access = await pool.query(
      'SELECT COUNT(*)::int AS count FROM pet_access WHERE pet_id = $1 AND user_id = $2',
      [petId, accepterId],
    );
    expect(access.rows[0].count).toBe(1);

    await pool.query('DELETE FROM pet_access WHERE pet_id = $1', [petId]);
    await pool.query('DELETE FROM notifications WHERE user_id IN ($1, $2)', [ownerId, accepterId]);
    await pool.query('DELETE FROM pet_share_links WHERE pet_id = $1', [petId]);
    await pool.query('DELETE FROM pets WHERE id = $1', [petId]);
    await pool.query('DELETE FROM users WHERE id = ANY($1::uuid[])', [[ownerId, accepterId]]);
  });
});
