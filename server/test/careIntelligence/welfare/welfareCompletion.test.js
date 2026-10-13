import { describe, expect, it } from '@jest/globals';
import request from 'supertest';
import jwt from 'jsonwebtoken';

import { createApp } from '../../../bin/server.js';
import * as welfareSync from '../../../routes/careIntelligence/welfare/syncPetWelfareSuggestions.js';
import { handlePetAccessQuery } from '../../helpers/petAccessMocks.js';
import { createMockPool, makePetRow, petId, userId } from '../../pets/helpers.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });

function welfareSyncFallback(sql, welfareRows) {
  if (sql.includes('pet_vaccination_records')) {
    return { rows: [] };
  }
  if (sql.includes('FROM welfare_suggestions WHERE pet_id = $1 AND dedupe_key')) {
    return { rows: [...welfareRows] };
  }
  if (sql.includes('UPDATE welfare_suggestions') && sql.includes('withdrawn')) {
    welfareRows.forEach((row) => {
      if (row.status === 'pending') {
        row.status = 'completed';
        row.primary_outcome = 'withdrawn';
      }
    });
    return { rows: [] };
  }
  if (sql.includes('FROM welfare_suggestions WHERE pet_id = $1 AND status')) {
    return { rows: welfareRows.filter((r) => r.status === 'pending') };
  }
  if (sql.startsWith('INSERT INTO welfare_suggestions')) {
    return { rows: [] };
  }
  return null;
}

describe('welfare completion on profile save (AC-FB-01)', () => {
  it('PUT pet chip save withdraws pending microchip welfare', async () => {
    const welfareRows = [
      {
        id: 'ws-1',
        pet_id: petId,
        subject_key: 'microchip_welfare',
        dedupe_key: `welfare:microchip:${petId}`,
        status: 'pending',
        primary_outcome: null,
      },
    ];

    let existing = makePetRow({
      identification_status: 'no',
      chip_id: '',
      neuter_status: 'yes',
      species: 'Dog',
    });

    const pool = createMockPool(async (sql, params) => {
      const access = handlePetAccessQuery(sql, params, {
        userId,
        ownedPetIds: [petId],
      });
      if (access) return access;

      const welfare = welfareSyncFallback(sql, welfareRows);
      if (welfare) return welfare;

      if (sql.includes('SELECT * FROM pets WHERE id = $1')) {
        return { rows: [existing] };
      }
      if (sql.includes('FROM weight_entries')) return { rows: [{ weight: 4.5 }] };
      if (sql.includes('INSERT INTO weight_entries')) return { rows: [] };
      if (sql.includes('UPDATE pets SET weight = (')) return { rows: [] };
      if (sql.includes('UPDATE pets SET name=$1')) {
        existing = {
          ...existing,
          chip_id: params[10],
          chip_dismissed: params[11],
          identification_status: params[12],
          neuter_status: params[13],
          species: params[1],
        };
        return { rows: [existing] };
      }
      return null;
    });

    const app = createApp(pool);
    const res = await request(app)
      .put(`/api/pets/${petId}`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 'Fluffy',
        species: 'Dog',
        identificationStatus: 'yes',
        chipId: '982000123456789',
      });

    expect(res.status).toBe(200);
    expect(welfareRows[0].status).toBe('completed');
    expect(welfareRows[0].primary_outcome).toBe('withdrawn');
  });

  it('sync withdraws pending row when chip recorded', async () => {
    const welfareRows = [
      {
        id: 'ws-1',
        pet_id: petId,
        subject_key: 'microchip_welfare',
        dedupe_key: `welfare:microchip:${petId}`,
        status: 'pending',
        primary_outcome: null,
      },
    ];

    const pool = createMockPool(async (sql) => {
      const welfare = welfareSyncFallback(sql, welfareRows);
      if (welfare) return welfare;
      return { rows: [] };
    });

    const pet = makePetRow({
      identification_status: 'yes',
      chip_id: '982000123456789',
      species: 'Dog',
    });

    await welfareSync.syncPetWelfareSuggestions(pool, pet);

    expect(welfareRows[0].status).toBe('completed');
    expect(welfareRows[0].primary_outcome).toBe('withdrawn');
  });
});
