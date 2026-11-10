import { relationshipRowToMap, RELATIONSHIP_LIST_SQL } from '../../lib/people/relationshipMapping.js';
import { CONTACT_ROLES_AGG_SQL } from '../../lib/people/contactRolesSql.js';

describe('relationshipMapping contact roles', () => {
  it('includes contact roles aggregation in list SQL', () => {
    expect(RELATIONSHIP_LIST_SQL).toContain(CONTACT_ROLES_AGG_SQL.trim().split('\n')[0]);
    expect(RELATIONSHIP_LIST_SQL).toContain('contact_roles');
  });

  it('maps contact.roles from contact_roles column', () => {
    const map = relationshipRowToMap({
      id: 'rel-1',
      pet_id: 'p1',
      contact_id: 'c1',
      relationship_kind: 'other',
      is_primary: false,
      active: true,
      sort_order: 0,
      contact_kind: 'person',
      contact_name: 'Jamie',
      contact_phone: null,
      contact_inactive_at: null,
      contact_roles: ['vet', 'vet_nurse'],
      created_at: new Date(),
      updated_at: new Date(),
    });
    expect(map.contact.roles).toEqual(['vet', 'vet_nurse']);
  });
});
