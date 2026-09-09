import {
  acknowledgeBundlePresented,
  computeDedupeKey,
  createMilestonesOnEstablishment,
  loadPendingMoments,
  MILESTONE_TYPES,
  PRESENTATION_THROTTLE_DAYS,
} from '../../../lib/care/progression/careMilestoneService.js';

const petId = 'pet-1';
const healthEntryId = 'he-weight';
const userId = 42;
const otherUserId = 99;

function makePool(handlers) {
  return {
    query: async (sql, params) => {
      for (const handler of handlers) {
        const result = await handler(sql, params);
        if (result !== undefined) return result;
      }
      throw new Error(`Unhandled query: ${sql}`);
    },
    connect: async () => {
      const client = {
        query: async (sql, params) => {
          for (const handler of handlers) {
            const result = await handler(sql, params);
            if (result !== undefined) return result;
          }
          throw new Error(`Unhandled client query: ${sql}`);
        },
        release: () => {},
      };
      return client;
    },
  };
}

describe('careMilestoneService', () => {
  it('computes frozen dedupe keys', () => {
    expect(computeDedupeKey(MILESTONE_TYPES.FIRST_CARE_ESTABLISHED)).toBe('first_care_established');
    expect(computeDedupeKey(MILESTONE_TYPES.WEIGHT_MONITORING_ESTABLISHED, { healthEntryId }))
      .toBe(`weight_monitoring_established:${healthEntryId}`);
  });

  it('creates bundled milestones on first establishment', async () => {
    const inserts = [];
    const pool = makePool([
      (sql) => {
        if (sql.includes('SELECT 1 FROM care_milestones')) {
          return { rows: [] };
        }
        return undefined;
      },
      (sql, params) => {
        if (sql.includes('INSERT INTO care_milestones')) {
          inserts.push(params);
          return {
            rows: [{
              id: `ms-${inserts.length}`,
              pet_id: petId,
              milestone_type: params[2],
              care_family: params[3],
              source_entity_id: params[4],
              dedupe_key: params[5],
              achieved_at: params[6],
              policy_version: params[7],
              bundle_id: params[8],
            }],
          };
        }
        return undefined;
      },
    ]);

    const outcome = await createMilestonesOnEstablishment(pool, {
      petId,
      careFamily: 'weight_monitoring',
      healthEntryId,
    });

    expect(outcome.bundled).toBe(true);
    expect(outcome.milestones).toHaveLength(2);
    expect(outcome.created_count).toBe(2);
    expect(inserts[0][8]).toBe(inserts[1][8]);
  });

  it('does not duplicate milestones on re-evaluation', async () => {
    const pool = makePool([
      (sql) => {
        if (sql.includes('SELECT 1 FROM care_milestones')) {
          return { rows: [{ id: 'existing-first' }] };
        }
        return undefined;
      },
      (sql) => {
        if (sql.includes('INSERT INTO care_milestones')) {
          return { rows: [] };
        }
        return undefined;
      },
      (sql, params) => {
        if (sql.includes('SELECT * FROM care_milestones WHERE pet_id = $1 AND dedupe_key = $2')) {
          return {
            rows: [{
              id: 'existing-weight',
              pet_id: petId,
              milestone_type: MILESTONE_TYPES.WEIGHT_MONITORING_ESTABLISHED,
              care_family: 'weight_monitoring',
              source_entity_id: healthEntryId,
              dedupe_key: params[1],
              achieved_at: new Date('2026-09-09T12:00:00.000Z'),
              policy_version: '1.0.0',
              bundle_id: 'bundle-1',
            }],
          };
        }
        return undefined;
      },
    ]);

    const outcome = await createMilestonesOnEstablishment(pool, {
      petId,
      careFamily: 'weight_monitoring',
      healthEntryId,
    });

    expect(outcome.created_count).toBe(0);
    expect(outcome.milestones).toHaveLength(1);
    expect(outcome.bundled).toBe(false);
  });

  it('returns pending moment bundle without presentation rows', async () => {
    const achievedAt = new Date('2026-09-09T12:00:00.000Z');
    const bundleId = 'bundle-abc';
    const pool = makePool([
      (sql) => {
        if (sql.includes('MAX(cmp.shown_at)')) return { rows: [{ last_shown_at: null }] };
        return undefined;
      },
      (sql) => {
        if (sql.includes('NOT EXISTS') && sql.includes('care_milestone_presentations')) {
          return {
            rows: [
              {
                id: 'ms-weight',
                pet_id: petId,
                milestone_type: MILESTONE_TYPES.WEIGHT_MONITORING_ESTABLISHED,
                care_family: 'weight_monitoring',
                source_entity_id: healthEntryId,
                achieved_at: achievedAt,
                policy_version: '1.0.0',
                bundle_id: bundleId,
              },
              {
                id: 'ms-first',
                pet_id: petId,
                milestone_type: MILESTONE_TYPES.FIRST_CARE_ESTABLISHED,
                care_family: null,
                source_entity_id: null,
                achieved_at: achievedAt,
                policy_version: '1.0.0',
                bundle_id: bundleId,
              },
            ],
          };
        }
        return undefined;
      },
    ]);

    const pending = await loadPendingMoments(pool, petId, userId);
    expect(pending.throttled).toBe(false);
    expect(pending.moments).toHaveLength(1);
    expect(pending.moments[0].bundle_id).toBe(bundleId);
    expect(pending.moments[0].includes_first_care).toBe(true);
    expect(pending.moments[0].milestones).toHaveLength(2);
  });

  it('throttles second moment within 30 days for same user', async () => {
    const recent = new Date();
    recent.setDate(recent.getDate() - (PRESENTATION_THROTTLE_DAYS - 1));
    const pool = makePool([
      (sql) => {
        if (sql.includes('MAX(cmp.shown_at)')) return { rows: [{ last_shown_at: recent }] };
        return undefined;
      },
    ]);

    const pending = await loadPendingMoments(pool, petId, userId);
    expect(pending.throttled).toBe(true);
    expect(pending.moments).toEqual([]);
  });

  it('does not throttle a different user when user A was presented', async () => {
    const achievedAt = new Date('2026-09-09T12:00:00.000Z');
    const pool = makePool([
      (sql, params) => {
        if (sql.includes('MAX(cmp.shown_at)')) {
          if (params[1] === otherUserId) return { rows: [{ last_shown_at: null }] };
          return { rows: [{ last_shown_at: new Date() }] };
        }
        return undefined;
      },
      (sql) => {
        if (sql.includes('NOT EXISTS') && sql.includes('care_milestone_presentations')) {
          return {
            rows: [{
              id: 'ms-weight',
              pet_id: petId,
              milestone_type: MILESTONE_TYPES.WEIGHT_MONITORING_ESTABLISHED,
              care_family: 'weight_monitoring',
              source_entity_id: healthEntryId,
              achieved_at: achievedAt,
              policy_version: '1.0.0',
              bundle_id: 'bundle-xyz',
            }],
          };
        }
        return undefined;
      },
    ]);

    const pending = await loadPendingMoments(pool, petId, otherUserId);
    expect(pending.throttled).toBe(false);
    expect(pending.moments).toHaveLength(1);
  });

  it('acknowledges all milestones in a bundle atomically', async () => {
    const bundleId = 'bundle-ack';
    const inserts = [];
    const pool = makePool([
      (sql) => {
        if (sql.includes('SELECT id FROM care_milestones') && sql.includes('bundle_id = $2')) {
          return { rows: [{ id: 'ms-1' }, { id: 'ms-2' }] };
        }
        return undefined;
      },
      (sql, params) => {
        if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') return { rows: [] };
        if (sql.includes('INSERT INTO care_milestone_presentations')) {
          inserts.push(params);
          return { rows: [] };
        }
        return undefined;
      },
    ]);

    const outcome = await acknowledgeBundlePresented(pool, {
      petId,
      userId,
      bundleId,
    });

    expect(outcome.acknowledged).toBe(true);
    expect(outcome.milestone_ids).toEqual(['ms-1', 'ms-2']);
    expect(inserts).toHaveLength(2);
    expect(inserts.every((params) => params[2] === userId)).toBe(true);
  });
});
