import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

import { evaluateMicrochipWelfare } from '../../../routes/careIntelligence/welfare/microchipWelfareEvaluator.js';
import { syncPetWelfareSuggestions } from '../../../routes/careIntelligence/welfare/syncPetWelfareSuggestions.js';

const __dirname = dirname(fileURLToPath(import.meta.url));
const fixtures = JSON.parse(
  readFileSync(join(__dirname, 'fixtures', 'microchip.json'), 'utf8'),
);

describe('microchip welfare evaluator (AC-WF-10 / ACJ-WF-07)', () => {
  for (const fixture of fixtures) {
    test(`fixture ${fixture.id}`, () => {
      const candidate = evaluateMicrochipWelfare(fixture.pet);
      if (fixture.expectCandidate) {
        expect(candidate).not.toBeNull();
        expect(candidate.subject_key).toBe('microchip_welfare');
        expect(candidate.dedupe_key).toBe(`welfare:microchip:${fixture.pet.id}`);
        expect(candidate.rationale_key).toBe('careWelfareMicrochipWhy');
      } else {
        expect(candidate).toBeNull();
      }
    });
  }

  test('sync upserts when identification_status is no', async () => {
    const queries = [];
    const pool = {
      query: jest.fn(async (sql, params) => {
        queries.push({ sql, params });
        if (sql.includes('SELECT * FROM welfare_suggestions WHERE pet_id')) {
          return { rows: [] };
        }
        if (sql.startsWith('INSERT INTO welfare_suggestions')) {
          return {
            rows: [{
              id: 'ws-new',
              pet_id: params[1],
              subject_key: params[2],
              dedupe_key: params[3],
              status: 'pending',
              rationale_key: params[4],
              engine_version: params[5],
              severity: params[6],
              created_at: new Date(),
              updated_at: new Date(),
            }],
          };
        }
        return { rows: [] };
      }),
    };
    await syncPetWelfareSuggestions(pool, {
      id: 'pet-1',
      identification_status: 'no',
      chip_id: '',
      chip_dismissed: false,
    });
    expect(pool.query).toHaveBeenCalledWith(
      expect.stringContaining('INSERT INTO welfare_suggestions'),
      expect.any(Array),
    );
  });

  test('sync withdraws pending row when no longer eligible', async () => {
    const pool = {
      query: jest.fn(async (sql) => {
        if (sql.includes('UPDATE welfare_suggestions') && sql.includes('withdrawn')) {
          return { rows: [] };
        }
        return { rows: [] };
      }),
    };
    await syncPetWelfareSuggestions(pool, {
      id: 'pet-1',
      identification_status: 'yes',
      chip_id: '',
      chip_dismissed: false,
    });
    expect(pool.query).toHaveBeenCalledWith(
      expect.stringContaining("primary_outcome = 'withdrawn'"),
      ['pet-1', 'welfare:microchip:pet-1'],
    );
  });
});
