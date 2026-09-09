import { v4 as uuidv4 } from 'uuid';

async function withOptionalTransaction(pool, fn) {
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

export const MILESTONE_POLICY_VERSION = '1.0.0';

export const MILESTONE_TYPES = {
  WEIGHT_MONITORING_ESTABLISHED: 'weight_monitoring_established',
  FIRST_CARE_ESTABLISHED: 'first_care_established',
};

export const PRESENTATION_THROTTLE_DAYS = 30;

/**
 * @param {string} milestoneType
 * @param {{ healthEntryId?: string }} [context]
 */
export function computeDedupeKey(milestoneType, { healthEntryId } = {}) {
  if (milestoneType === MILESTONE_TYPES.FIRST_CARE_ESTABLISHED) {
    return 'first_care_established';
  }
  if (milestoneType === MILESTONE_TYPES.WEIGHT_MONITORING_ESTABLISHED) {
    if (!healthEntryId) {
      throw new Error('healthEntryId is required for weight_monitoring_established dedupe key');
    }
    return `weight_monitoring_established:${healthEntryId}`;
  }
  throw new Error(`Unknown milestone type: ${milestoneType}`);
}

/**
 * @param {object} row
 */
export function milestoneToDto(row) {
  return {
    id: row.id,
    milestone_type: row.milestone_type,
    care_family: row.care_family,
    source_entity_id: row.source_entity_id,
    achieved_at: row.achieved_at instanceof Date
      ? row.achieved_at.toISOString()
      : row.achieved_at,
    policy_version: row.policy_version,
    bundle_id: row.bundle_id,
  };
}

/**
 * @param {import('pg').Pool | import('pg').PoolClient} db
 * @param {object} params
 */
async function insertMilestoneIdempotent(db, params) {
  const id = uuidv4();
  const result = await db.query(
    `INSERT INTO care_milestones
      (id, pet_id, milestone_type, care_family, source_entity_id, dedupe_key,
       achieved_at, policy_version, bundle_id)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
     ON CONFLICT (pet_id, dedupe_key) DO NOTHING
     RETURNING *`,
    [
      id,
      params.petId,
      params.milestoneType,
      params.careFamily,
      params.sourceEntityId,
      params.dedupeKey,
      params.achievedAt,
      params.policyVersion,
      params.bundleId,
    ],
  );

  if (result.rows.length > 0) {
    return { created: true, row: result.rows[0] };
  }

  const existing = await db.query(
    `SELECT * FROM care_milestones WHERE pet_id = $1 AND dedupe_key = $2`,
    [params.petId, params.dedupeKey],
  );
  return { created: false, row: existing.rows[0] || null };
}

/**
 * @param {import('pg').Pool} pool
 * @param {string} petId
 */
async function petHasFirstCareMilestone(pool, petId) {
  const result = await pool.query(
    `SELECT 1 FROM care_milestones
     WHERE pet_id = $1 AND milestone_type = $2
     LIMIT 1`,
    [petId, MILESTONE_TYPES.FIRST_CARE_ESTABLISHED],
  );
  return result.rows.length > 0;
}

/**
 * Create milestones when a care family becomes established (idempotent).
 *
 * @param {import('pg').Pool} pool
 * @param {{ petId: string, careFamily: string, healthEntryId: string, achievedAt?: Date }} params
 */
export async function createMilestonesOnEstablishment(pool, {
  petId,
  careFamily,
  healthEntryId,
  achievedAt = new Date(),
}) {
  const bundleId = uuidv4();
  const created = [];
  const isFirstCare = !(await petHasFirstCareMilestone(pool, petId));

  const familyOutcome = await insertMilestoneIdempotent(pool, {
    petId,
    milestoneType: MILESTONE_TYPES.WEIGHT_MONITORING_ESTABLISHED,
    careFamily,
    sourceEntityId: healthEntryId,
    dedupeKey: computeDedupeKey(MILESTONE_TYPES.WEIGHT_MONITORING_ESTABLISHED, { healthEntryId }),
    achievedAt,
    policyVersion: MILESTONE_POLICY_VERSION,
    bundleId: isFirstCare ? bundleId : bundleId,
  });
  if (familyOutcome.row) {
    created.push(familyOutcome);
  }

  if (isFirstCare) {
    const firstOutcome = await insertMilestoneIdempotent(pool, {
      petId,
      milestoneType: MILESTONE_TYPES.FIRST_CARE_ESTABLISHED,
      careFamily: null,
      sourceEntityId: null,
      dedupeKey: computeDedupeKey(MILESTONE_TYPES.FIRST_CARE_ESTABLISHED),
      achievedAt,
      policyVersion: MILESTONE_POLICY_VERSION,
      bundleId,
    });
    if (firstOutcome.row) {
      created.push(firstOutcome);
    }
  }

  const rows = created.map((item) => item.row).filter(Boolean);
  const bundled = isFirstCare && rows.length > 1;

  return {
    milestones: rows.map(milestoneToDto),
    bundled,
    bundle_id: bundled ? bundleId : rows[0]?.bundle_id || null,
    created_count: created.filter((item) => item.created).length,
  };
}

/**
 * @param {import('pg').Pool} pool
 * @param {string} petId
 */
export async function loadMilestonesForPet(pool, petId) {
  const result = await pool.query(
    `SELECT id, pet_id, milestone_type, care_family, source_entity_id,
            achieved_at, policy_version, bundle_id
     FROM care_milestones
     WHERE pet_id = $1
     ORDER BY achieved_at ASC`,
    [petId],
  );
  return result.rows.map(milestoneToDto);
}

/**
 * @param {import('pg').Pool} pool
 * @param {string} petId
 * @param {number} userId
 */
async function lastPresentationAt(pool, petId, userId) {
  const result = await pool.query(
    `SELECT MAX(cmp.shown_at) AS last_shown_at
     FROM care_milestone_presentations cmp
     JOIN care_milestones cm ON cm.id = cmp.milestone_id
     WHERE cm.pet_id = $1 AND cmp.user_id = $2`,
    [petId, userId],
  );
  return result.rows[0]?.last_shown_at || null;
}

function isWithinThrottle(lastShownAt) {
  if (!lastShownAt) return false;
  const last = lastShownAt instanceof Date ? lastShownAt : new Date(lastShownAt);
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - PRESENTATION_THROTTLE_DAYS);
  return last > cutoff;
}

/**
 * @param {object[]} rows
 */
function groupPendingMoments(rows) {
  const byBundle = new Map();
  for (const row of rows) {
    const key = row.bundle_id || row.id;
    if (!byBundle.has(key)) {
      byBundle.set(key, []);
    }
    byBundle.get(key).push(row);
  }

  const moments = [];
  for (const bundleRows of byBundle.values()) {
    const sorted = [...bundleRows].sort((a, b) => {
      if (a.milestone_type === MILESTONE_TYPES.WEIGHT_MONITORING_ESTABLISHED) return -1;
      if (b.milestone_type === MILESTONE_TYPES.WEIGHT_MONITORING_ESTABLISHED) return 1;
      return 0;
    });
    const primary = sorted.find(
      (row) => row.milestone_type !== MILESTONE_TYPES.FIRST_CARE_ESTABLISHED,
    ) || sorted[0];
    const includesFirstCare = sorted.some(
      (row) => row.milestone_type === MILESTONE_TYPES.FIRST_CARE_ESTABLISHED,
    );

    moments.push({
      bundle_id: primary.bundle_id || primary.id,
      primary_milestone_type: primary.milestone_type,
      includes_first_care: includesFirstCare,
      achieved_at: primary.achieved_at instanceof Date
        ? primary.achieved_at.toISOString()
        : primary.achieved_at,
      milestones: sorted.map(milestoneToDto),
    });
  }

  moments.sort((a, b) => a.achieved_at.localeCompare(b.achieved_at));
  return moments;
}

/**
 * @param {import('pg').Pool} pool
 * @param {string} petId
 * @param {number} userId
 */
export async function loadPendingMoments(pool, petId, userId) {
  const lastShown = await lastPresentationAt(pool, petId, userId);
  if (isWithinThrottle(lastShown)) {
    return { moments: [], throttled: true };
  }

  const result = await pool.query(
    `SELECT cm.*
     FROM care_milestones cm
     WHERE cm.pet_id = $1
       AND NOT EXISTS (
         SELECT 1 FROM care_milestone_presentations cmp
         WHERE cmp.milestone_id = cm.id AND cmp.user_id = $2
       )
     ORDER BY cm.achieved_at ASC`,
    [petId, userId],
  );

  if (result.rows.length === 0) {
    return { moments: [], throttled: false };
  }

  const moments = groupPendingMoments(result.rows);
  return { moments: moments.slice(0, 1), throttled: false };
}

/**
 * @param {import('pg').Pool} pool
 * @param {{ petId: string, userId: number, bundleId: string }} params
 */
export async function acknowledgeBundlePresented(pool, { petId, userId, bundleId }) {
  const milestonesResult = await pool.query(
    `SELECT id FROM care_milestones
     WHERE pet_id = $1 AND (bundle_id = $2 OR id = $2)`,
    [petId, bundleId],
  );

  if (milestonesResult.rows.length === 0) {
    return { acknowledged: false, reason: 'bundle_not_found' };
  }

  const milestoneIds = milestonesResult.rows.map((row) => row.id);

  await withOptionalTransaction(pool, async (client) => {
    for (const milestoneId of milestoneIds) {
      await client.query(
        `INSERT INTO care_milestone_presentations (id, milestone_id, user_id)
         VALUES ($1, $2, $3)
         ON CONFLICT (milestone_id, user_id) DO NOTHING`,
        [uuidv4(), milestoneId, userId],
      );
    }
  });

  return {
    acknowledged: true,
    milestone_ids: milestoneIds,
  };
}
