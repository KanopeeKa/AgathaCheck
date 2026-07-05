import {
  computePlacementOutcome,
  getOrgPersonDetail,
  linkExternalFostersByEmail,
  listFosterContactsForUser,
  parsePersonRef,
  personCategoryRank,
  personDetailToMap,
  personRef,
  personSummaryToMap,
} from '../lib/orgPeople.js';

describe('orgPeople helpers', () => {
  describe('personCategoryRank', () => {
    it('ranks super admins first', () => {
      expect(personCategoryRank('super_admin', 'member')).toBe(1);
      expect(personCategoryRank('pending_super_admin', 'member')).toBe(1);
    });

    it('ranks admins second', () => {
      expect(personCategoryRank('admin', 'member')).toBe(2);
      expect(personCategoryRank('pending_admin', 'member')).toBe(2);
    });

    it('ranks foster members third', () => {
      expect(personCategoryRank('foster', 'member')).toBe(3);
    });

    it('ranks external fosters last', () => {
      expect(personCategoryRank(null, 'external')).toBe(4);
    });
  });

  describe('personRef / parsePersonRef', () => {
    it('builds and parses a person reference', () => {
      expect(personRef('external', 'fp-1')).toBe('external:fp-1');
      expect(parsePersonRef('member:ou-9')).toEqual({ kind: 'member', id: 'ou-9' });
    });

    it('returns null for invalid references', () => {
      expect(parsePersonRef('invalid')).toBeNull();
      expect(parsePersonRef(':missing-kind')).toBeNull();
    });
  });

  describe('personSummaryToMap', () => {
    it('maps database row to API summary', () => {
      const summary = personSummaryToMap({
        kind: 'external',
        record_id: 'fp-1',
        user_id: null,
        display_name: ' Off-app Parent ',
        email: 'off@example.com',
        role: null,
        photo_url: null,
        is_pending: false,
        active_foster_count: '2',
        category_rank: 4,
      });

      expect(summary).toMatchObject({
        id: 'external:fp-1',
        kind: 'external',
        record_id: 'fp-1',
        display_name: 'Off-app Parent',
        email: 'off@example.com',
        active_foster_count: 2,
        category_rank: 4,
      });
    });

    it('falls back to email when display name is blank', () => {
      const summary = personSummaryToMap({
        kind: 'external',
        record_id: 'fp-2',
        display_name: '   ',
        email: 'only@example.com',
        active_foster_count: 0,
        category_rank: 4,
      });

      expect(summary.display_name).toBe('only@example.com');
    });
  });

  describe('personDetailToMap', () => {
    it('includes contact fields and placement extras', () => {
      const detail = personDetailToMap(
        {
          kind: 'external',
          record_id: 'fp-1',
          display_name: 'Parent',
          email: 'parent@example.com',
          foster_phone: '555',
          foster_address: 'Addr',
          admin_notes: 'Notes',
          active_foster_count: 0,
          category_rank: 4,
        },
        {
          current_placements: [{ id: 'pl-1' }],
          past_placements: [{ id: 'pl-0', outcome: 'adopted' }],
        },
      );

      expect(detail.foster_phone).toBe('555');
      expect(detail.foster_address).toBe('Addr');
      expect(detail.admin_notes).toBe('Notes');
      expect(detail.current_placements).toHaveLength(1);
      expect(detail.past_placements).toHaveLength(1);
    });
  });

  describe('computePlacementOutcome', () => {
    it('returns passed_away when pet passed away', () => {
      expect(
        computePlacementOutcome({ status: 'not_in_foster' }, true, false),
      ).toBe('passed_away');
    });

    it('returns adopted for adopted placements', () => {
      expect(
        computePlacementOutcome({ status: 'adopted' }, false, false),
      ).toBe('adopted');
    });

    it('returns in_foster_elsewhere when pet moved to another foster', () => {
      expect(
        computePlacementOutcome({ status: 'not_in_foster' }, false, true),
      ).toBe('in_foster_elsewhere');
    });

    it('defaults to not_in_foster', () => {
      expect(
        computePlacementOutcome({ status: 'not_in_foster' }, false, false),
      ).toBe('not_in_foster');
    });
  });

  describe('linkExternalFostersByEmail', () => {
    it('updates unmatched external foster rows for the email', async () => {
      const calls = [];
      const pool = {
        query: async (sql, params) => {
          calls.push({ sql, params });
          return { rows: [] };
        },
      };

      await linkExternalFostersByEmail(pool, 'user-1', ' Foster@Example.com ');

      expect(calls).toHaveLength(1);
      expect(calls[0].sql).toContain('UPDATE org_foster_parents');
      expect(calls[0].params).toEqual(['user-1', 'Foster@Example.com']);
    });

    it('no-ops when email is missing', async () => {
      const pool = {
        query: jest.fn(),
      };

      await linkExternalFostersByEmail(pool, 'user-1', '');
      expect(pool.query).not.toHaveBeenCalled();
    });
  });

  describe('listFosterContactsForUser', () => {
    it('returns member and external foster contacts for the user', async () => {
      const pool = {
        query: async (sql) => {
          if (sql.includes('SELECT email FROM users')) {
            return { rows: [{ email: 'foster@example.com' }] };
          }
          if (sql.includes("'member' AS kind")) {
            return {
              rows: [{
                kind: 'member',
                record_id: 'ou-1',
                organization_id: 'org-1',
                organization_name: 'Shelter',
                display_name: 'Jane Foster',
                email: 'foster@example.com',
                role: 'foster',
                foster_phone: '555',
                foster_address: 'Addr',
                admin_notes: 'Notes',
              }],
            };
          }
          if (sql.includes("'external' AS kind")) {
            return {
              rows: [{
                kind: 'external',
                record_id: 'fp-1',
                organization_id: 'org-1',
                organization_name: 'Shelter',
                display_name: 'Off-app Parent',
                email: 'foster@example.com',
                role: null,
                foster_phone: '444',
                foster_address: '',
                admin_notes: '',
              }],
            };
          }
          return { rows: [] };
        },
      };

      const contacts = await listFosterContactsForUser(pool, 'user-1');

      expect(contacts).toHaveLength(2);
      expect(contacts[0]).toMatchObject({
        kind: 'member',
        record_id: 'ou-1',
        organization_name: 'Shelter',
        role: 'foster',
      });
      expect(contacts[1]).toMatchObject({
        kind: 'external',
        record_id: 'fp-1',
        role: null,
      });
    });

    it('returns empty list when user has no email', async () => {
      const pool = {
        query: async () => ({ rows: [] }),
      };

      const contacts = await listFosterContactsForUser(pool, 'user-1');
      expect(contacts).toEqual([]);
    });
  });

  describe('getOrgPersonDetail', () => {
    it('loads member detail and placement queries use the fp alias', async () => {
      const placementSqls = [];
      const pool = {
        query: async (sql, params) => {
          if (sql.includes('FROM organization_users ou') && sql.includes('ou.id = $2')) {
            return {
              rows: [{
                kind: 'member',
                record_id: 'ou-1',
                user_id: 'user-1',
                display_name: 'Admin User',
                email: 'admin@example.com',
                photo_url: null,
                role: 'admin',
                is_pending: false,
                foster_phone: '',
                foster_address: '',
                admin_notes: '',
                active_foster_count: 0,
              }],
            };
          }
          if (sql.includes('FROM foster_placements fp')) {
            placementSqls.push(sql);
            return { rows: [] };
          }
          if (sql.includes('SELECT DISTINCT ON (pet_id)')) {
            return { rows: [] };
          }
          return { rows: [] };
        },
      };

      const detail = await getOrgPersonDetail(pool, 'org-1', 'member', 'ou-1');

      expect(detail).toMatchObject({
        kind: 'member',
        record_id: 'ou-1',
        display_name: 'Admin User',
        role: 'admin',
      });
      expect(placementSqls).toHaveLength(1);
      expect(placementSqls[0]).toContain('fp.foster_user_id = $2');
      expect(placementSqls[0]).not.toContain('fpl.');
    });

    it('loads external foster detail and placement queries use the fp alias', async () => {
      const placementSqls = [];
      const pool = {
        query: async (sql) => {
          if (sql.includes('FROM org_foster_parents fp') && sql.includes('fp.id = $2')) {
            return {
              rows: [{
                kind: 'external',
                record_id: 'fp-1',
                user_id: null,
                display_name: 'Off-app Parent',
                email: 'off@example.com',
                photo_url: null,
                role: null,
                is_pending: false,
                foster_phone: '',
                foster_address: '',
                admin_notes: '',
                active_foster_count: 0,
              }],
            };
          }
          if (sql.includes('FROM foster_placements fp')) {
            placementSqls.push(sql);
            return { rows: [] };
          }
          if (sql.includes('SELECT DISTINCT ON (pet_id)')) {
            return { rows: [] };
          }
          return { rows: [] };
        },
      };

      const detail = await getOrgPersonDetail(pool, 'org-1', 'external', 'fp-1');

      expect(detail).toMatchObject({
        kind: 'external',
        record_id: 'fp-1',
        display_name: 'Off-app Parent',
      });
      expect(placementSqls).toHaveLength(1);
      expect(placementSqls[0]).toContain('fp.org_foster_parent_id = $2');
      expect(placementSqls[0]).not.toContain('fpl.');
    });
  });
});
