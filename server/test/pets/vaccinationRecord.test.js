import { describe, expect, it } from '@jest/globals';
import request from 'supertest';
import { createApp } from '../../bin/server.js';
import {
  computeVaccinationSummary,
  vaccinationRecordToMap,
} from '../../lib/pets/vaccinationRecords.js';
import { handlePetAccessQuery } from '../helpers/petAccessMocks.js';
import {
  createMockPool,
  makePetRow,
  petId,
  token,
  userId,
} from './helpers.js';

describe('vaccination record helpers', () => {
  it('computeVaccinationSummary uses latest administered_on', () => {
    const summary = computeVaccinationSummary([
      { administered_on: '2026-06-01' },
      { administered_on: '2025-01-01' },
    ]);
    expect(summary).toEqual({
      record_count: 2,
      last_administered_on: '2026-06-01',
    });
  });

  it('vaccinationRecordToMap uses calendar date wire format', () => {
    const map = vaccinationRecordToMap({
      id: 'vx-1',
      pet_id: petId,
      vaccine_name: 'Rabies',
      administered_on: '2026-03-15',
      record_source: 'user',
      created_at: new Date('2026-03-16T10:00:00.000Z'),
      updated_at: new Date('2026-03-16T10:00:00.000Z'),
    });
    expect(map.administered_on).toBe('2026-03-15');
    expect(map.vaccine_name).toBe('Rabies');
  });
});

describe('pet vaccination records API (ACJ-VX-01 / AC-VX-01)', () => {
  it('ACJ-VX-01 POST persists minimum record and GET returns computed summary', async () => {
    const rows = [];
    const pool = createMockPool(async (sql, params) => {
      const access = handlePetAccessQuery(sql, params, {
        userId,
        ownedPetIds: [petId],
        healthView: true,
        healthEdit: true,
      });
      if (access) return access;
      if (sql.includes('SELECT id FROM pets WHERE id = $1')) {
        return { rows: [{ id: petId }] };
      }
      if (sql.includes('INSERT INTO pet_vaccination_records')) {
        const row = {
          id: params[0],
          pet_id: params[1],
          vaccine_name: params[2],
          administered_on: params[3],
          record_source: params[4],
          created_by: params[5],
          created_at: new Date('2026-10-13T12:00:00.000Z'),
          updated_at: new Date('2026-10-13T12:00:00.000Z'),
        };
        rows.push(row);
        return { rows: [row] };
      }
      if (sql.includes('FROM pet_vaccination_records')) {
        return { rows: [...rows] };
      }
      if (sql.includes('SELECT * FROM pets WHERE id = $1')) {
        return { rows: [makePetRow()] };
      }
      return null;
    });
    const app = createApp(pool);

    const post = await request(app)
      .post(`/api/pets/${petId}/vaccination-records`)
      .set('Authorization', `Bearer ${token}`)
      .send({ vaccineName: 'DHPP', administeredOn: '2026-09-01' });
    expect(post.statusCode).toBe(201);
    expect(post.body.vaccine_name).toBe('DHPP');
    expect(post.body.administered_on).toBe('2026-09-01');

    const get = await request(app)
      .get(`/api/pets/${petId}/vaccination-records`)
      .set('Authorization', `Bearer ${token}`);
    expect(get.statusCode).toBe(200);
    expect(get.body.records).toHaveLength(1);
    expect(get.body.summary.record_count).toBe(1);
    expect(get.body.summary.last_administered_on).toBe('2026-09-01');
  });

  it('POST rejects missing vaccine_name', async () => {
    const pool = createMockPool(async (sql, params) => {
      const access = handlePetAccessQuery(sql, params, {
        userId,
        ownedPetIds: [petId],
        healthEdit: true,
      });
      if (access) return access;
      if (sql.includes('SELECT id FROM pets')) {
        return { rows: [{ id: petId }] };
      }
      return null;
    });
    const app = createApp(pool);
    const res = await request(app)
      .post(`/api/pets/${petId}/vaccination-records`)
      .set('Authorization', `Bearer ${token}`)
      .send({ administeredOn: '2026-09-01' });
    expect(res.statusCode).toBe(400);
  });
});
