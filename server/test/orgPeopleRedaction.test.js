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
    user_id: 'user-1',
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

  const limitedViewer = {
    userId: 'viewer-1',
    role: 'associate',
    permissionKeys: [],
  };

  const adminViewer = {
    userId: 'admin-1',
    role: 'admin',
    permissionKeys: [],
  };

  const openPrivacy = {
    card_visibility: 'all',
    phone_visibility: 'admins_or_named',
    email_visibility: 'admins_or_named',
    address_visibility: 'admins_or_named',
  };

  it('viewerHasFullPeopleAccess is a legacy stub (privacy resolver owns access)', () => {
    expect(viewerHasFullPeopleAccess('super_admin')).toBe(false);
    expect(viewerHasFullPeopleAccess('admin')).toBe(false);
    expect(viewerHasFullPeopleAccess('foster')).toBe(false);
  });

  it('redactPersonSummary without viewer returns the person unchanged', () => {
    expect(redactPersonSummary(summary, false)).toEqual(summary);
  });

  it('redactPersonSummary hides member when card is not visible to viewer', () => {
    const redacted = redactPersonSummary(
      summary,
      false,
      limitedViewer,
      { ...openPrivacy, card_visibility: 'admins' },
      [],
    );
    expect(redacted.active_foster_count).toBe(0);
    expect(redacted.display_name).toBe('');
    expect(redacted.email).toBeNull();
  });

  it('redactPersonSummary preserves foster counts for admins with card access', () => {
    const redacted = redactPersonSummary(summary, true, adminViewer, openPrivacy, []);
    expect(redacted.active_foster_count).toBe(3);
    expect(redacted.email).toBe('grace@example.com');
  });

  it('redactPersonDetail strips contact fields for limited viewers', () => {
    const redacted = redactPersonDetail(detail, false, limitedViewer, openPrivacy, []);
    expect(redacted.foster_phone).toBe('');
    expect(redacted.foster_address).toBe('');
    expect(redacted.admin_notes).toBe('');
  });

  it('redactPersonDetail keeps contact fields for admins under admins_or_named', () => {
    const redacted = redactPersonDetail(detail, true, adminViewer, openPrivacy, []);
    expect(redacted.foster_phone).toBe('555-1234');
    expect(redacted.admin_notes).toBe('Notes');
    expect(redacted.current_placements).toEqual([{ id: 'pl-1' }]);
  });
});
