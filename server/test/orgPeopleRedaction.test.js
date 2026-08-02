import {
  redactPersonDetail,
  redactPersonSummary,
  viewerHasFullPeopleAccess,
} from '../lib/orgPeople.js';

describe('orgPeople redaction', () => {
  const summary = {
    id: 'member:ou-1',
    kind: 'member',
    record_id: 'ou-1',
    display_name: 'Grace Admin',
    email: 'grace@example.com',
    role: 'admin',
    active_foster_count: 3,
    category_rank: 2,
  };

  const detail = {
    ...summary,
    foster_phone: '555-1234',
    foster_address: '1 Main St',
    admin_notes: 'Notes',
    current_placements: [{ id: 'pl-1' }],
    past_placements: [{ id: 'pl-2', outcome: 'adopted' }],
  };

  it('viewerHasFullPeopleAccess is true only for org admins', () => {
    expect(viewerHasFullPeopleAccess('super_admin')).toBe(true);
    expect(viewerHasFullPeopleAccess('admin')).toBe(true);
    expect(viewerHasFullPeopleAccess('foster')).toBe(false);
    expect(viewerHasFullPeopleAccess('associate')).toBe(false);
  });

  it('redactPersonSummary clears foster counts for limited viewers', () => {
    const redacted = redactPersonSummary(summary, false);
    expect(redacted.active_foster_count).toBe(0);
    expect(redacted.display_name).toBe('Grace Admin');
    expect(redacted.email).toBe('grace@example.com');
  });

  it('redactPersonSummary preserves full payload for admins', () => {
    expect(redactPersonSummary(summary, true)).toEqual(summary);
  });

  it('redactPersonDetail strips contact fields and placements', () => {
    const redacted = redactPersonDetail(detail, false);
    expect(redacted.foster_phone).toBe('');
    expect(redacted.foster_address).toBe('');
    expect(redacted.admin_notes).toBe('');
    expect(redacted.current_placements).toEqual([]);
    expect(redacted.past_placements).toEqual([]);
    expect(redacted.email).toBe('grace@example.com');
  });
});
