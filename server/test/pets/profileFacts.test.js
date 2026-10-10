import { describe, expect, it } from '@jest/globals';
import request from 'supertest';
import {
  createMockPool,
  makePetRow,
  petId,
  token,
  userId,
} from './helpers.js';
import { createApp } from '../../bin/server.js';
import { handlePetAccessQuery } from '../helpers/petAccessMocks.js';
import {
  mergeProfileFactsFromBody,
  normaliseProfileFacts,
  parseProfileFactStatus,
} from '../../lib/pets/profileFacts.js';
import { updatePet } from '../../lib/pets/petCoreCommandService.js';

describe('profileFacts helpers', () => {
  it('parseProfileFactStatus rejects invalid enum', () => {
    expect(parseProfileFactStatus('maybe').ok).toBe(false);
  });

  it('AC-PF-06 normalises identification to yes when chip_id is set', () => {
    const merged = mergeProfileFactsFromBody(
      { identificationStatus: 'unknown', chipId: 'ABC' },
      makePetRow(),
    );
    expect(merged.ok).toBe(true);
    const norm = normaliseProfileFacts(merged.patch, null);
    expect(norm.ok).toBe(true);
    expect(norm.patch.identification_status).toBe('yes');
  });

  it('AC-PF-06 rejects neuter_status no when neutered_date is set', () => {
    const merged = mergeProfileFactsFromBody(
      { neuterStatus: 'no' },
      makePetRow({ neuter_status: 'no' }),
    );
    const norm = normaliseProfileFacts(merged.patch, '2022-06-01');
    expect(norm.ok).toBe(false);
  });

  it('AC-PF-05 keeps statuses when omitted (old client chipId empty)', () => {
    const existing = makePetRow({
      identification_status: 'yes',
      neuter_status: 'no',
      chip_id: 'CHIP-001',
    });
    const merged = mergeProfileFactsFromBody(
      { name: 'X', chipId: '' },
      existing,
    );
    expect(merged.ok).toBe(true);
    expect(merged.patch.identification_status).toBe('yes');
    expect(merged.patch.neuter_status).toBe('no');
    expect(merged.patch.chip_id).toBe('');
  });

  it('AC-PF-07 keeps chip_id when chipId omitted', () => {
    const existing = makePetRow({ chip_id: 'KEEP-ME' });
    const merged = mergeProfileFactsFromBody({ name: 'X' }, existing);
    expect(merged.patch.chip_id).toBe('KEEP-ME');
  });
});

describe('profileFacts updatePet', () => {
  const orgViewerId = 'org-viewer-id';

  function poolForUpdate(existing, onUpdate) {
    return createMockPool(async (sql, params) => {
      const access = handlePetAccessQuery(sql, params, {
        userId,
        ownedPetIds: [petId],
        orgViewerId,
        orgViewerCanView: true,
      });
      if (access) return access;
      if (sql.includes('SELECT * FROM pets WHERE id = $1')) {
        return { rows: [existing] };
      }
      if (sql.includes('FROM weight_entries')) return { rows: [{ weight: 4.5 }] };
      if (sql.includes('INSERT INTO weight_entries')) return { rows: [] };
      if (sql.includes('UPDATE pets SET weight = (')) return { rows: [] };
      if (sql.includes('UPDATE pets SET name=$1')) {
        if (onUpdate) onUpdate(params);
        const updated = { ...existing, ...rowFromUpdateParams(params) };
        return { rows: [updated] };
      }
      if (sql.includes('SELECT * FROM pets WHERE id = $1') && sql.includes('RETURNING')) {
        return { rows: [existing] };
      }
      if (sql.includes('SELECT * FROM pets WHERE id = $1')) {
        return { rows: [existing] };
      }
      return null;
    });
  }

  function rowFromUpdateParams(params) {
    return {
      chip_id: params[10],
      neuter_status: params[13],
      identification_status: params[12],
    };
  }

  it('AC-PF-01 neuter_status no survives update when omitted', async () => {
    const existing = makePetRow({ neuter_status: 'no' });
    let captured;
    const pool = poolForUpdate(existing, (p) => { captured = p; });
    const out = await updatePet(pool, userId, petId, {
      name: 'Fluffy',
      species: 'cat',
    }, {});
    expect(out.pet.neuterStatus).toBe('no');
    expect(captured[13]).toBe('no');
  });

  it('AC-PF-02 identification_status yes and chip on GET wire', async () => {
    const existing = makePetRow({
      identification_status: 'yes',
      chip_id: 'CHIP-XYZ',
    });
    const pool = poolForUpdate(existing);
    const out = await updatePet(pool, userId, petId, {
      name: 'Fluffy',
      species: 'cat',
      identificationStatus: 'yes',
      chipId: 'CHIP-XYZ',
    }, {});
    expect(out.pet.identificationStatus).toBe('yes');
    expect(out.pet.chipId).toBe('CHIP-XYZ');
  });
});

describe('PUT /api/pets/:id profile facts', () => {
  it('AC-PF-04 invalid identification_status returns 400', async () => {
    const app = createApp(createMockPool(async (sql, params) => {
      const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: [petId] });
      if (access) return access;
      if (sql.includes('SELECT * FROM pets WHERE id = $1')) {
        return { rows: [makePetRow()] };
      }
      return null;
    }));
    const res = await request(app)
      .put(`/api/pets/${petId}`)
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Fluffy', species: 'cat', identificationStatus: 'maybe' });
    expect(res.statusCode).toBe(400);
    expect(res.body.error).toMatch(/identification_status/i);
  });
});
