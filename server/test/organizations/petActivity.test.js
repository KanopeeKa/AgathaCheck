import {
  PET_ACTIVITY_EVENT_TYPES,
  PET_ACTIVITY_HOOK_MANIFEST,
  sanitizePetActivityMetadata,
  recordPetActivity,
  recordPetActivityForPet,
  recordPetActivitySafe,
  lookupPetOrgId,
} from '../../lib/petActivity.js';

describe('petActivity', () => {
  describe('sanitizePetActivityMetadata', () => {
    it('keeps allowed keys only (D-v2-ACT-3)', () => {
      const safe = sanitizePetActivityMetadata('health_log', {
        action: 'create',
        entry_type: 'vet_visit',
        notes: 'sensitive payload',
        pet_name: 'Fluffy',
      });
      expect(safe).toEqual({ action: 'create', entry_type: 'vet_visit' });
      expect(safe).not.toHaveProperty('notes');
      expect(safe).not.toHaveProperty('pet_name');
    });

    it('filters changed_fields to string keys only', () => {
      const safe = sanitizePetActivityMetadata('profile_edit', {
        field_count: 2,
        changed_fields: ['breed', '', 42, 'weight'],
      });
      expect(safe).toEqual({
        field_count: 2,
        changed_fields: ['breed', 'weight'],
      });
    });

    it('returns empty object for unknown event types', () => {
      expect(sanitizePetActivityMetadata('unknown', { action: 'x' })).toEqual({});
    });
  });

  describe('recordPetActivity', () => {
    it('inserts event and updates last_activity_at in one transaction', async () => {
      const queries = [];
      const client = {
        query: jest.fn(async (sql, params) => {
          queries.push({ sql, params });
          return { rows: [{ id: params?.[0] }] };
        }),
        release: jest.fn(),
      };
      const pool = {
        connect: jest.fn(async () => client),
      };

      const eventId = await recordPetActivity(pool, {
        petId: 'pet-1',
        orgId: 'org-1',
        actorUserId: 'user-1',
        eventType: 'health_log',
        metadata: { action: 'create', entry_type: 'vet_visit' },
      });

      expect(eventId).toBeTruthy();
      expect(pool.connect).toHaveBeenCalled();
      expect(queries[0].sql).toBe('BEGIN');
      expect(queries[1].sql).toContain('INSERT INTO pet_activity_events');
      expect(queries[1].params[1]).toBe('pet-1');
      expect(queries[1].params[2]).toBe('org-1');
      expect(queries[1].params[3]).toBe('health_log');
      expect(JSON.parse(queries[1].params[5])).toEqual({
        action: 'create',
        entry_type: 'vet_visit',
      });
      expect(queries[2].sql).toContain('UPDATE pets SET last_activity_at');
      expect(queries[3].sql).toBe('COMMIT');
      expect(client.release).toHaveBeenCalled();
    });

    it('rolls back when insert fails', async () => {
      const queries = [];
      const client = {
        query: jest.fn(async (sql) => {
          queries.push(sql);
          if (sql.includes('INSERT INTO pet_activity_events')) {
            throw new Error('insert failed');
          }
          return { rows: [] };
        }),
        release: jest.fn(),
      };
      const pool = { connect: jest.fn(async () => client) };

      await expect(
        recordPetActivity(pool, {
          petId: 'pet-1',
          orgId: 'org-1',
          eventType: 'profile_edit',
        }),
      ).rejects.toThrow('insert failed');

      expect(queries).toContain('ROLLBACK');
      expect(client.release).toHaveBeenCalled();
    });

    it('returns null when required fields are missing', async () => {
      const pool = { connect: jest.fn() };
      expect(await recordPetActivity(pool, { petId: 'pet-1' })).toBeNull();
      expect(pool.connect).not.toHaveBeenCalled();
    });

    it('returns null for invalid event types', async () => {
      const pool = { connect: jest.fn() };
      expect(
        await recordPetActivity(pool, {
          petId: 'pet-1',
          orgId: 'org-1',
          eventType: 'not_valid',
        }),
      ).toBeNull();
      expect(pool.connect).not.toHaveBeenCalled();
    });

    it('works without pool.connect for test mock pools', async () => {
      const queries = [];
      const pool = {
        query: jest.fn(async (sql, params) => {
          queries.push({ sql, params });
          return { rows: [] };
        }),
      };

      const eventId = await recordPetActivity(pool, {
        petId: 'pet-1',
        orgId: 'org-1',
        eventType: 'document_upload',
        metadata: { document_count: 1 },
      });

      expect(eventId).toBeTruthy();
      expect(queries).toHaveLength(2);
      expect(queries[0].sql).toContain('INSERT INTO pet_activity_events');
      expect(queries[1].sql).toContain('UPDATE pets SET last_activity_at');
    });
  });

  describe('recordPetActivitySafe', () => {
    it('logs and returns null on failure without throwing', async () => {
      const pool = {
        connect: jest.fn(async () => {
          throw new Error('no db');
        }),
      };
      const result = await recordPetActivitySafe(pool, {
        petId: 'pet-1',
        orgId: 'org-1',
        eventType: 'health_log',
      });
      expect(result).toBeNull();
    });
  });

  describe('lookupPetOrgId', () => {
    it('returns organization_id from pets row', async () => {
      const pool = {
        query: jest.fn(async () => ({ rows: [{ organization_id: 'org-9' }] })),
      };
      await expect(lookupPetOrgId(pool, 'pet-1')).resolves.toBe('org-9');
    });

    it('returns null when pet has no org', async () => {
      const pool = {
        query: jest.fn(async () => ({ rows: [{ organization_id: null }] })),
      };
      await expect(lookupPetOrgId(pool, 'pet-1')).resolves.toBeNull();
    });
  });

  describe('recordPetActivityForPet', () => {
    it('skips when pet has no organization', async () => {
      const pool = {
        query: jest.fn(async () => ({ rows: [{ organization_id: null }] })),
      };
      const result = await recordPetActivityForPet(pool, {
        petId: 'pet-1',
        actorUserId: 'user-1',
        eventType: 'health_log',
      });
      expect(result).toBeNull();
      expect(pool.query).toHaveBeenCalledTimes(1);
    });

    it('records activity when pet belongs to an org', async () => {
      const queries = [];
      const pool = {
        query: jest.fn(async (sql, params) => {
          queries.push({ sql, params });
          if (sql.includes('SELECT organization_id')) {
            return { rows: [{ organization_id: 'org-1' }] };
          }
          return { rows: [] };
        }),
      };

      await recordPetActivityForPet(pool, {
        petId: 'pet-1',
        actorUserId: 'user-1',
        eventType: 'health_log',
        metadata: { action: 'update', entry_type: 'weight' },
      });

      expect(queries.some((q) => q.sql.includes('INSERT INTO pet_activity_events'))).toBe(true);
      expect(queries.some((q) => q.sql.includes('UPDATE pets SET last_activity_at'))).toBe(true);
    });
  });

  describe('PET_ACTIVITY_EVENT_TYPES', () => {
    it('lists the v1 event types', () => {
      expect(PET_ACTIVITY_EVENT_TYPES).toEqual([
        'health_log',
        'foster_session',
        'profile_edit',
        'document_upload',
      ]);
    });
  });

  describe('PET_ACTIVITY_HOOK_MANIFEST', () => {
    it('covers all four event type categories', () => {
      const types = new Set(PET_ACTIVITY_HOOK_MANIFEST.map((entry) => entry.eventType));
      expect(types).toEqual(new Set(PET_ACTIVITY_EVENT_TYPES));
    });
  });
});
