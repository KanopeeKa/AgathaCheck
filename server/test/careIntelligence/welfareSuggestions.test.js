import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../bin/server.js';
import { handlePetAccessQuery } from '../helpers/petAccessMocks.js';
import {
  isWelfareDedupeSuppressed,
  upsertWelfareSuggestionCandidate,
  WELFARE_DISMISS_SUPPRESS_DAYS,
} from '../../routes/careIntelligence/welfareSuggestionsService.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });

const baseCandidate = {
  subject_key: 'microchip_welfare',
  dedupe_key: 'welfare:microchip:pet-1',
  rationale_key: 'careWelfareMicrochipWhy',
  engine_version: '1.0.0',
  severity: 5,
};

function makeRow(overrides = {}) {
  const now = new Date('2026-10-01T12:00:00.000Z');
  return {
    id: 'ws-1',
    pet_id: 'pet-1',
    subject_key: baseCandidate.subject_key,
    dedupe_key: baseCandidate.dedupe_key,
    status: 'pending',
    primary_outcome: null,
    rationale_key: baseCandidate.rationale_key,
    engine_version: '1.0.0',
    severity: 5,
    dismissed_until: null,
    responded_at: null,
    created_at: now,
    updated_at: now,
    ...overrides,
  };
}

describe('welfare suggestions service (AC-WF-01…03)', () => {
  test('AC-WF-03 isWelfareDedupeSuppressed within 30d after dismiss', () => {
    const until = new Date('2026-10-20T00:00:00.000Z');
    const row = makeRow({
      status: 'dismissed',
      dismissed_until: until,
    });
    expect(isWelfareDedupeSuppressed(row, new Date('2026-10-10T00:00:00.000Z'))).toBe(true);
    expect(isWelfareDedupeSuppressed(row, new Date('2026-10-21T00:00:00.000Z'))).toBe(false);
  });

  test('AC-WF-02 upsert refreshes pending row for same dedupe_key', async () => {
    const rows = [makeRow()];
    const pool = {
      query: jest.fn(async (sql, params) => {
        if (sql.includes('SELECT * FROM welfare_suggestions WHERE pet_id')) {
          return { rows: [...rows] };
        }
        if (sql.startsWith('UPDATE welfare_suggestions')) {
          rows[0] = {
            ...rows[0],
            rationale_key: params[1],
            severity: params[3],
          };
          return { rows: [rows[0]] };
        }
        return { rows: [] };
      }),
    };
    const updated = await upsertWelfareSuggestionCandidate(
      pool,
      'pet-1',
      { ...baseCandidate, rationale_key: 'careWelfareMicrochipWhyV2', severity: 8 },
    );
    expect(updated.rationale_key).toBe('careWelfareMicrochipWhyV2');
    expect(updated.severity).toBe(8);
    expect(pool.query).toHaveBeenCalledWith(
      expect.stringContaining('UPDATE welfare_suggestions'),
      expect.any(Array),
    );
  });

  test('AC-WF-03 upsert does not reopen dismissed row inside suppress window', async () => {
    const dismissedUntil = new Date('2026-10-25T00:00:00.000Z');
    const rows = [
      makeRow({
        status: 'dismissed',
        dismissed_until: dismissedUntil,
      }),
    ];
    const pool = {
      query: jest.fn(async () => ({ rows: [...rows] })),
    };
    const now = new Date('2026-10-10T00:00:00.000Z');
    const result = await upsertWelfareSuggestionCandidate(
      pool,
      'pet-1',
      baseCandidate,
      now,
    );
    expect(result.status).toBe('dismissed');
    expect(pool.query).toHaveBeenCalledTimes(1);
  });

  test('AC-WF-01 inserts new row when dedupe_key unseen', async () => {
    const inserted = [];
    const pool = {
      query: jest.fn(async (sql) => {
        if (sql.includes('SELECT * FROM welfare_suggestions')) {
          return { rows: [] };
        }
        if (sql.startsWith('INSERT INTO welfare_suggestions')) {
          const row = makeRow({ id: 'new-id' });
          inserted.push(row);
          return { rows: [row] };
        }
        return { rows: [] };
      }),
    };
    const row = await upsertWelfareSuggestionCandidate(pool, 'pet-1', baseCandidate);
    expect(row.pet_id).toBe('pet-1');
    expect(row.dedupe_key).toBe(baseCandidate.dedupe_key);
    expect(inserted).toHaveLength(1);
  });

  test('dismiss suppress window uses 30 days constant', () => {
    expect(WELFARE_DISMISS_SUPPRESS_DAYS).toBe(30);
  });
});

describe('Welfare suggestions API', () => {
  let app;
  let welfareRows;
  let pets;

  beforeAll(() => {
    welfareRows = [];
    pets = [{ id: 'pet-1', species: 'Dog' }];

    const mockPool = {
      query: async (sql, params) => {
        const access = handlePetAccessQuery(sql, params, {
          userId,
          ownedPetIds: ['pet-1'],
        });
        if (access) return access;

        if (sql.includes('FROM pets p') && sql.includes('WHERE p.id')) {
          const pet = pets.find((p) => p.id === params[0]);
          return { rows: pet ? [pet] : [] };
        }

        if (sql.includes('FROM welfare_suggestions WHERE pet_id = $1 AND status')) {
          return {
            rows: welfareRows.filter(
              (r) => r.pet_id === params[0] && r.status === 'pending',
            ),
          };
        }

        if (sql.includes('FROM welfare_suggestions WHERE id = $1')) {
          const row = welfareRows.find(
            (r) => r.id === params[0] && r.pet_id === params[1],
          );
          return { rows: row ? [row] : [] };
        }

        if (sql.startsWith('UPDATE welfare_suggestions') && sql.includes('dismissed')) {
          const id = params[2];
          const row = welfareRows.find((r) => r.id === id);
          if (!row) return { rows: [] };
          row.status = 'dismissed';
          row.dismissed_until = params[0];
          row.responded_at = params[1];
          return { rows: [row] };
        }

        return { rows: [] };
      },
    };

    app = createApp(mockPool);
  });

  test('AC-WF-01 GET returns pending welfare suggestions', async () => {
    welfareRows.length = 0;
    welfareRows.push(makeRow());

    const res = await request(app)
      .get('/api/pets/pet-1/welfare-suggestions')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(1);
    expect(res.body[0].subject_key).toBe('microchip_welfare');
    expect(res.body[0].dedupe_key).toBe(baseCandidate.dedupe_key);
  });

  test('AC-WF-03 POST dismiss sets suppress metadata', async () => {
    welfareRows.length = 0;
    welfareRows.push(makeRow());

    const res = await request(app)
      .post('/api/pets/pet-1/welfare-suggestions/ws-1/respond')
      .set('Authorization', `Bearer ${token}`)
      .send({ action: 'dismiss' });

    expect(res.status).toBe(200);
    expect(res.body.status).toBe('dismissed');
    expect(res.body.dismissed_until).toBeTruthy();
    expect(welfareRows[0].status).toBe('dismissed');
  });
});
