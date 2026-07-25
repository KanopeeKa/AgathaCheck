import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../bin/server.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const orgId = 'org-1';
const memberId = 'member-user-id';
const inviteId = 'invite-1';

export function makeOrgRow(overrides = {}) {
  return {
    id: orgId,
    name: 'Test Org',
    type: 'professional',
    email: 'org@test.com',
    phone: '555-1234',
    address: '123 Main St',
    website: 'https://test.org',
    bio: 'A test organization',
    photo_url: '/photos/org.jpg',
    logo_url: '/photos/org-logo.jpg',
    primary_contact_ref: null,
    role: 'super_admin',
    member_count: '2',
    external_count: '1',
    pet_count: '1',
    created_at: new Date('2024-01-01'),
    updated_at: new Date('2024-06-01'),
    ...overrides,
  };
}

export function buildMockPool(overrides = {}) {
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

  const defaultHandler = async (sql, params) => {
    if (sql.includes('SELECT o.*') && sql.includes('ORDER BY o.name')) {
      return { rows: [makeOrgRow()] };
    }
    if (sql.includes('INSERT INTO organizations')) {
      return { rows: [] };
    }
    if (sql.includes('INSERT INTO organization_users') && !sql.includes('ON CONFLICT')) {
      return { rows: [] };
    }
    if (sql.includes("SELECT o.*, 'super_admin' as role")) {
      return { rows: [makeOrgRow({ role: 'super_admin', member_count: '1', pet_count: '0' })] };
    }
    if (sql.includes('SELECT o.*') && sql.includes('WHERE o.id')) {
      return { rows: [makeOrgRow()] };
    }
    if (sql.includes('UPDATE organizations SET')) {
      return { rows: [] };
    }
    if (sql.includes('DELETE FROM organizations')) {
      return { rows: [makeOrgRow()] };
    }
    if (sql.includes('SELECT ou.id, ou.organization_id')) {
      return {
        rows: [{
          id: inviteId,
          organization_id: orgId,
          role: 'pending_admin',
          org_name: 'Test Org',
          org_type: 'professional',
        }],
      };
    }
    if (sql.includes("UPDATE organization_users SET role = REPLACE")) {
      return {
        rows: [{
          id: inviteId,
          organization_id: orgId,
          role: 'admin',
          user_id: userId,
        }],
      };
    }
    if (sql.includes("DELETE FROM organization_users WHERE id")) {
      return { rows: [] };
    }
    if (sql.includes('SELECT ou.id, ou.role, ou.created_at, u.id as user_id')) {
      return {
        rows: [{
          id: 'ou-1',
          user_id: userId,
          email: 'test@example.com',
          first_name: 'Test',
          last_name: 'User',
          photo_url: '/photos/user.jpg',
          role: 'super_admin',
          created_at: new Date('2024-01-01'),
        }],
      };
    }
    if (sql.includes('SELECT id FROM users WHERE email')) {
      return { rows: [{ id: memberId }] };
    }
    if (sql.includes('INSERT INTO organization_users') && sql.includes('ON CONFLICT')) {
      return { rows: [] };
    }
    if (sql.includes('UPDATE organization_users SET role = $1')) {
      return {
        rows: [{ id: 'ou-1', organization_id: orgId, user_id: memberId, role: 'admin' }],
      };
    }
    if (sql.includes('DELETE FROM organization_users WHERE organization_id') && sql.includes('AND user_id = $2')) {
      return { rows: [] };
    }
    if (sql.includes('FROM pets p') && sql.includes('organization_name')) {
      return {
        rows: [{
          id: 'pet-1',
          name: 'Buddy',
          species: 'dog',
          breed: 'Labrador',
          organization_id: orgId,
          organization_name: 'Happy Paws',
        }],
      };
    }
    if (sql.includes('SELECT * FROM archived_pets WHERE organization_id')) {
      return { rows: [] };
    }
    if (sql.includes('SELECT name FROM organizations WHERE id')) {
      return { rows: [{ name: 'Test Org' }] };
    }
    if (sql.includes("'member' AS kind") && sql.includes('record_id')) {
      return {
        rows: [{
          kind: 'member',
          record_id: 'ou-1',
          user_id: userId,
          display_name: 'Test User',
          email: 'test@example.com',
          photo_url: '/photos/user.jpg',
          role: 'super_admin',
          is_pending: false,
          active_foster_count: 1,
        }],
      };
    }
    if (sql.includes("'external' AS kind") && sql.includes('record_id')) {
      return {
        rows: [{
          kind: 'external',
          record_id: 'fp-external-1',
          user_id: null,
          display_name: 'Off-app Parent',
          email: 'offapp@example.com',
          photo_url: null,
          role: null,
          is_pending: false,
          active_foster_count: 0,
        }],
      };
    }
    if (sql.includes("'member' AS kind") && sql.includes('organization_users ou')) {
      return {
        rows: [{
          id: 'ou-foster-1',
          kind: 'member',
          user_id: 'foster-user-1',
          foster_profile_id: 'fprof-member-1',
          display_name: 'Jane Foster',
          email: 'jane@example.com',
          photo_url: '/photos/jane.jpg',
          role: 'foster',
          phone: null,
          notes: '',
          active_pet_count: 2,
          active_pets: [{ pet_id: 'pet-a', pet_name: 'Max', status: 'in_progress' }],
          approval_state: 'approved',
          creation_source: 'member',
        }],
      };
    }
    if (sql.includes('INSERT INTO pets (id, user_id')) {
      return {
        rows: [{
          id: params[0],
          name: params[2],
          species: params[3],
          breed: params[4] || '',
          organization_id: orgId,
          date_of_birth: null,
        }],
      };
    }
    if (sql.includes("'external' AS kind") && sql.includes('org_foster_parents')) {
      return {
        rows: [{
          id: 'fp-external-1',
          kind: 'external',
          user_id: null,
          foster_profile_id: 'fprof-external-1',
          display_name: 'Off-app Parent',
          email: 'offapp@example.com',
          photo_url: null,
          role: null,
          phone: '555-0000',
          notes: 'No account',
          active_pet_count: 0,
          approval_state: 'approved',
          creation_source: 'manual_shelter_entry',
          opt_out_at: null,
          retention_category: 'manual_contact',
        }],
      };
    }
    if (sql.includes('INSERT INTO foster_profiles')) {
      return { rows: [] };
    }
    if (sql.includes('INSERT INTO org_foster_parents')) {
      return {
        rows: [{
          id: 'fp-new-1',
          organization_id: orgId,
          display_name: 'New Parent',
          email: 'new@example.com',
          phone: null,
          notes: '',
          foster_profile_id: 'fprof-new-1',
          approval_state: 'under_review',
          creation_source: 'manual_shelter_entry',
        }],
      };
    }
    if (sql.includes('SET approval_state = $1')) {
      const approvalState = params[0];
      return {
        rows: [{
          id: 'fp-external-1',
          organization_id: orgId,
          display_name: 'Off-app Parent',
          email: 'offapp@example.com',
          phone: '555-0000',
          notes: 'No account',
          approval_state: approvalState,
          creation_source: 'manual_shelter_entry',
        }],
      };
    }
    if (sql.includes('FROM users u') && sql.includes('LOWER(u.email)')) {
      return {
        rows: [{
          user_id: 'registered-user-1',
          display_name: 'Registered User',
          email: 'match@example.com',
          foster_profile_id: 'fprof-registered-1',
        }],
      };
    }
    if (sql.includes('SELECT * FROM org_foster_parents') && sql.includes('organization_id = $2')) {
      return {
        rows: [{
          id: 'fp-external-1',
          organization_id: orgId,
          user_id: null,
          foster_profile_id: 'fprof-external-1',
          display_name: 'Off-app Parent',
          email: 'match@example.com',
          phone: '555-0000',
          foster_address: '',
          notes: '',
          approval_state: 'approved',
          creation_source: 'manual_shelter_entry',
        }],
      };
    }
    if (sql.includes('SELECT id, email, first_name, last_name FROM users WHERE id')) {
      return {
        rows: [{
          id: 'registered-user-1',
          email: 'match@example.com',
          first_name: 'Registered',
          last_name: 'User',
        }],
      };
    }
    if (sql.includes('SELECT id FROM foster_profiles WHERE user_id')) {
      return { rows: [{ id: 'fprof-registered-1' }] };
    }
    if (sql.includes('UPDATE org_foster_parents') && sql.includes('foster_profile_id = $2')) {
      return {
        rows: [{
          id: 'fp-external-1',
          organization_id: orgId,
          user_id: 'registered-user-1',
          foster_profile_id: 'fprof-registered-1',
          display_name: 'Off-app Parent',
          email: 'match@example.com',
          phone: '555-0000',
          foster_address: '',
          notes: '',
          approval_state: 'approved',
          creation_source: 'manual_shelter_entry',
        }],
      };
    }
    if (sql.includes('SELECT COUNT(*)::int AS count FROM org_foster_parents WHERE foster_profile_id')) {
      return { rows: [{ count: 0 }] };
    }
    if (sql.includes('DELETE FROM foster_profiles WHERE id')) {
      return { rows: [] };
    }
    if (sql.includes('UPDATE org_foster_parents') && sql.includes('opt_out_at')) {
      return {
        rows: [{
          id: 'fp-external-1',
          organization_id: orgId,
          user_id: null,
          foster_profile_id: 'fprof-external-1',
          display_name: 'Off-app Parent',
          email: 'offapp@example.com',
          phone: '555-0000',
          foster_address: '',
          notes: '',
          approval_state: 'approved',
          creation_source: 'manual_shelter_entry',
          opt_out_at: params[0] ? new Date('2026-07-25T12:00:00Z') : null,
          retention_category: 'manual_contact',
        }],
      };
    }
    if (sql.includes('UPDATE org_foster_parents') && sql.includes('retention_category = $1')) {
      return {
        rows: [{
          id: 'fp-external-1',
          organization_id: orgId,
          display_name: 'Off-app Parent',
          email: 'offapp@example.com',
          retention_category: params[0],
          approval_state: 'approved',
          creation_source: 'manual_shelter_entry',
        }],
      };
    }
    if (sql.includes('UPDATE org_foster_parents')) {
      return {
        rows: [{
          id: 'fp-external-1',
          organization_id: orgId,
          display_name: 'Updated Parent',
          email: 'updated@example.com',
          phone: '555-1111',
          notes: 'Updated',
          approval_state: 'approved',
          creation_source: 'manual_shelter_entry',
        }],
      };
    }
    if (sql.includes('DELETE FROM org_foster_parents')) {
      return { rows: [{ id: 'fp-external-1' }] };
    }
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
    return { rows: [] };
  };

  // The authorization guards (requireMember/requireAdmin) issue a membership
  // lookup. Layer it on top of any custom query override so guard behavior can
  // be controlled per-test via `memberRole` without each override re-declaring
  // it: 'super_admin' (default), 'admin', 'foster', or null (non-member).
  const memberRole = overrides.memberRole === undefined ? 'super_admin' : overrides.memberRole;
  const inner = overrides.query || defaultHandler;
  const query = async (sql, params) => {
    if (sql.includes('SELECT role FROM organization_users WHERE organization_id')) {
      return { rows: memberRole ? [{ role: memberRole }] : [] };
    }
    return inner(sql, params);
  };

  return {
    query,
    connect: async () => ({
      query,
      release: () => {},
    }),
    end: async () => {},
  };
}