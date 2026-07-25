export function createFosteringMockState(orgId, userId) {
  const fosterRequests = new Map([
    ['fr-sent-1', {
      id: 'fr-sent-1',
      organization_id: orgId,
      message: 'Can you help with these pets?',
      status: 'sent',
      created_by: userId,
      sent_at: new Date('2026-07-25T10:00:00Z'),
      created_at: new Date('2026-07-25T09:00:00Z'),
      updated_at: new Date('2026-07-25T10:00:00Z'),
    }],
    ['fr-draft-1', {
      id: 'fr-draft-1',
      organization_id: orgId,
      message: 'Draft outreach',
      status: 'draft',
      created_by: userId,
      sent_at: null,
      created_at: new Date('2026-07-25T09:00:00Z'),
      updated_at: new Date('2026-07-25T09:00:00Z'),
    }],
  ]);
  const fosterResponses = new Map([
    ['fr-sent-1', [{
      id: 'frr-1',
      foster_request_id: 'fr-sent-1',
      org_foster_parent_id: 'fp-member-1',
      response: 'can_help',
      message: 'Happy to help',
      earliest_availability: '2026-08-01',
      capacity_confirmed_at: new Date('2026-07-25T11:00:00Z'),
      responded_at: new Date('2026-07-25T11:00:00Z'),
      created_at: new Date('2026-07-25T10:00:00Z'),
      updated_at: new Date('2026-07-25T11:00:00Z'),
    }]],
  ]);
  return { fosterRequests, fosterResponses };
}

export async function handleFosteringOrgQueries(sql, params, { orgId, userId, fosterRequests, fosterResponses }) {
  if (sql.includes('FROM foster_requests fr') && sql.includes('WHERE fr.organization_id')) {
      return {
        rows: [...fosterRequests.values()].map((row) => ({
          ...row,
          pet_ids: ['pet-1'],
          target_count: 1,
          pending_count: row.status === 'sent' ? 0 : 0,
          can_help_count: row.id === 'fr-sent-1' ? 1 : 0,
          cannot_help_count: 0,
        })),
      };
    }
  if (sql.includes('INSERT INTO foster_requests')) {
      const row = {
        id: params[0],
        organization_id: params[1],
        message: params[2],
        status: 'draft',
        created_by: params[3],
        sent_at: null,
        created_at: new Date('2026-07-25T12:00:00Z'),
        updated_at: new Date('2026-07-25T12:00:00Z'),
      };
      fosterRequests.set(row.id, row);
      return { rows: [row] };
    }
  if (sql.includes('FROM pets') && sql.includes('passed_away') && sql.includes('ANY($2::uuid[])')) {
      const requested = params[1] || [];
      const found = requested.filter((id) => id === 'pet-1' || id === 'pet-a');
      return { rows: found.map((id) => ({ id })) };
    }
  if (sql.includes('FROM org_foster_parents fp') && sql.includes('opt_out_at IS NULL')) {
      const requested = params[1] || [];
      const eligible = {
        'fp-external-1': {
          org_foster_parent_id: 'fp-external-1',
          display_name: 'Off-app Parent',
          email: 'offapp@example.com',
          user_id: null,
          approval_state: 'approved',
          opt_out_at: null,
        },
        'fp-member-1': {
          org_foster_parent_id: 'fp-member-1',
          display_name: 'Jane Foster',
          email: 'jane@example.com',
          user_id: 'foster-user-1',
          approval_state: 'approved',
          opt_out_at: null,
        },
      };
      return {
        rows: requested
          .map((id) => eligible[id])
          .filter(Boolean),
      };
    }
  if (sql.includes('INSERT INTO foster_request_pets')
      || sql.includes('INSERT INTO foster_request_targets')
      || sql.includes('INSERT INTO foster_request_responses')) {
      return { rows: [] };
    }
  if (sql.includes('UPDATE foster_requests') && sql.includes("status = 'sent'")) {
      const requestId = params[0];
      const existing = fosterRequests.get(requestId);
    if (!existing) {
        return { rows: [] };
      }
      const updated = {
        ...existing,
        status: 'sent',
        sent_at: new Date('2026-07-25T12:00:00Z'),
        updated_at: new Date('2026-07-25T12:00:00Z'),
      };
      fosterRequests.set(requestId, updated);
      return { rows: [updated] };
    }
  if (sql.includes('SELECT *') && sql.includes('FROM foster_requests') && sql.includes('WHERE id = $1 AND organization_id = $2')) {
      const requestId = params[0];
    if (requestId === 'fr-missing') {
        return { rows: [] };
      }
      const row = fosterRequests.get(requestId);
      return { rows: row ? [row] : [] };
    }
  if (sql.includes('SELECT id, status') && sql.includes('FROM foster_requests')) {
      const requestId = params[0];
      const row = fosterRequests.get(requestId);
      return { rows: row ? [{ id: row.id, status: row.status }] : [] };
    }
  if (sql.includes('FROM foster_request_pets frp')) {
      return {
        rows: [{
          pet_id: 'pet-1',
          pet_name: 'Buddy',
          species: 'dog',
        }],
      };
    }
  if (sql.includes('FROM foster_request_targets frt')) {
      return {
        rows: [{
          org_foster_parent_id: 'fp-member-1',
          display_name: 'Jane Foster',
          email: 'jane@example.com',
          user_id: 'foster-user-1',
          approval_state: 'approved',
          opt_out_at: null,
        }],
      };
    }
  if (sql.includes('FROM foster_request_responses') && sql.includes('ORDER BY created_at')) {
      const requestId = params[0];
      const rows = fosterResponses.get(requestId) || [];
      return { rows };
    }
  if (sql.includes('FROM foster_request_targets frt') && sql.includes('opt_out_at IS NULL')) {
      return { rows: [{ org_foster_parent_id: 'fp-member-1' }] };
    }
  if (sql.includes('JOIN foster_request_targets frt') && sql.includes('fp.user_id = $3')) {
      const fosterUserId = params[2];
    if (fosterUserId === 'foster-user-1') {
        return {
          rows: [{
            foster_request_id: params[0],
            status: 'sent',
            org_foster_parent_id: 'fp-member-1',
          }],
        };
      }
      return { rows: [] };
    }
  if (sql.includes('FROM prospects') && sql.includes('WHERE organization_id = $1') && sql.includes('ORDER BY display_name')) {
      return {
        rows: [{
          id: 'prospect-1',
          organization_id: orgId,
          display_name: 'Adopter Prospect',
          email: 'prospect@example.com',
          phone: '555-2222',
          notes: 'Interested in cats',
          user_id: null,
          creation_source: 'manual_shelter_entry',
          lawful_basis_attested_at: new Date('2026-07-25T10:00:00Z'),
          lawful_basis_attested_by: userId,
          opt_out_at: null,
          retention_category: 'manual_contact',
          created_by: userId,
          created_at: new Date('2026-07-25T10:00:00Z'),
          updated_at: new Date('2026-07-25T10:00:00Z'),
        }],
      };
    }
  if (sql.includes('INSERT INTO prospects')) {
      return {
        rows: [{
          id: 'prospect-new-1',
          organization_id: orgId,
          display_name: 'New Prospect',
          email: 'newprospect@example.com',
          phone: null,
          notes: '',
          user_id: null,
          creation_source: 'manual_shelter_entry',
          lawful_basis_attested_at: new Date('2026-07-25T12:00:00Z'),
          lawful_basis_attested_by: userId,
          opt_out_at: null,
          retention_category: 'manual_contact',
          created_by: userId,
          created_at: new Date('2026-07-25T12:00:00Z'),
          updated_at: new Date('2026-07-25T12:00:00Z'),
        }],
      };
    }
  if (sql.includes('FROM users u') && sql.includes('LOWER(u.email) = LOWER($1)') && !sql.includes('foster_profiles')) {
      return {
        rows: [{
          user_id: 'registered-user-1',
          display_name: 'Registered User',
          email: 'match@example.com',
        }],
      };
    }
  if (sql.includes('SELECT * FROM prospects') && sql.includes('organization_id = $2')) {
      return {
        rows: [{
          id: 'prospect-1',
          organization_id: orgId,
          user_id: null,
          display_name: 'Adopter Prospect',
          email: 'match@example.com',
          phone: '555-2222',
          notes: 'Interested in cats',
          creation_source: 'manual_shelter_entry',
          retention_category: 'manual_contact',
        }],
      };
    }
  if (sql.includes('UPDATE prospects') && sql.includes('user_id = $1')) {
      return {
        rows: [{
          id: 'prospect-1',
          organization_id: orgId,
          user_id: 'registered-user-1',
          display_name: 'Adopter Prospect',
          email: 'match@example.com',
          phone: '555-2222',
          notes: 'Interested in cats',
          creation_source: 'manual_shelter_entry',
          retention_category: 'prospect_relationship',
        }],
      };
    }
  if (sql.includes('UPDATE prospects') && sql.includes('display_name = $1')) {
      return {
        rows: [{
          id: 'prospect-1',
          organization_id: orgId,
          display_name: params[0],
          email: params[1],
          phone: params[2],
          notes: 'Interested in cats',
          user_id: null,
          creation_source: 'manual_shelter_entry',
          retention_category: 'manual_contact',
        }],
      };
    }
  if (sql.includes('UPDATE foster_request_responses')) {
      const updated = {
        id: 'frr-1',
        foster_request_id: params[4],
        org_foster_parent_id: params[5],
        response: params[0],
        message: params[1],
        earliest_availability: params[2],
        capacity_confirmed_at: params[3],
        responded_at: new Date('2026-07-25T12:00:00Z'),
        created_at: new Date('2026-07-25T10:00:00Z'),
        updated_at: new Date('2026-07-25T12:00:00Z'),
      };
      fosterResponses.set(params[4], [updated]);
      return { rows: [updated] };
    }

  return null;
}
