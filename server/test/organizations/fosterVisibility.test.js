import {
  applyFosterVisibilityToMap,
  canViewerSeeFosterCard,
  contactFieldsForViewer,
  formatAddressForViewer,
  normaliseAddressVisibility,
  normaliseContactVisibility,
  normaliseVisibleTo,
  sortFosterParentsForViewer,
} from '../../lib/fosterVisibility.js';
import { withdrawFosterAgreement, isWithdrawConfirmationValid } from '../../lib/fosterAgreementWithdrawal.js';

describe('fosterVisibility', () => {
  const baseParent = {
    user_id: 'foster-1',
    display_name: 'Jane Foster',
    email: 'jane@example.com',
    phone: '555-0100',
    foster_address: '12 Oak Lane, Springfield',
    visible_to: 'both',
    address_visibility: 'full',
    contact_visibility: 'both',
  };

  it('shows full address by default to another foster', () => {
    const filtered = applyFosterVisibilityToMap(baseParent, {
      viewerRole: 'associate',
      viewerUserId: 'other-foster',
      viewerIsFosterParent: true,
    });
    expect(filtered?.foster_address).toBe('12 Oak Lane, Springfield');
    expect(filtered?.email).toBe('jane@example.com');
  });

  it('restricts address to town only for viewers', () => {
    const parent = {
      ...baseParent,
      address_visibility: 'town',
    };
    const filtered = applyFosterVisibilityToMap(parent, {
      viewerRole: 'associate',
      viewerUserId: 'other-foster',
      viewerIsFosterParent: true,
    });
    expect(filtered?.foster_address).toBe('Springfield');
  });

  it('hides card when visible_to is nobody for non-self viewers', () => {
    const parent = { ...baseParent, visible_to: 'nobody' };
    expect(canViewerSeeFosterCard({
      visibleTo: parent.visible_to,
      viewerRole: 'associate',
      viewerUserId: 'other',
      fosterUserId: parent.user_id,
      viewerIsFosterParent: true,
    })).toBe(false);
    expect(applyFosterVisibilityToMap(parent, {
      viewerRole: 'associate',
      viewerUserId: 'other',
      viewerIsFosterParent: true,
    })).toBeNull();
  });

  it('allows admins to see admin-only cards', () => {
    const parent = { ...baseParent, visible_to: 'admins' };
    expect(canViewerSeeFosterCard({
      visibleTo: parent.visible_to,
      viewerRole: 'admin',
      viewerUserId: 'admin-1',
      fosterUserId: parent.user_id,
    })).toBe(true);
    expect(canViewerSeeFosterCard({
      visibleTo: parent.visible_to,
      viewerRole: 'foster',
      viewerUserId: 'other',
      fosterUserId: parent.user_id,
    })).toBe(false);
  });

  it('respects contact visibility settings', () => {
    const contacts = contactFieldsForViewer({
      email: 'jane@example.com',
      phone: '555',
      contactVisibility: 'email',
      viewerRole: 'associate',
      viewerUserId: 'other',
      fosterUserId: 'foster-1',
      viewerIsFosterParent: true,
    });
    expect(contacts).toEqual({ email: 'jane@example.com', phone: null });
  });

  it('pins self card first when sorting', () => {
    const sorted = sortFosterParentsForViewer([
      { user_id: 'b', display_name: 'Bob Alpha' },
      { user_id: 'self', display_name: 'Self User' },
      { user_id: 'a', display_name: 'Amy Zulu' },
    ], 'self');
    expect(sorted[0].user_id).toBe('self');
    expect(sorted[1].display_name).toBe('Bob Alpha');
  });

  it('normalises invalid visibility values to permissive defaults', () => {
    expect(normaliseVisibleTo('invalid')).toBe('both');
    expect(normaliseAddressVisibility(null)).toBe('full');
    expect(normaliseContactVisibility(undefined)).toBe('both');
    expect(formatAddressForViewer('1 Main, Town', 'town')).toBe('Town');
  });
});

describe('fosterAgreementWithdrawal', () => {
  it('requires literal withdraw confirmation', () => {
    expect(isWithdrawConfirmationValid('withdraw')).toBe(true);
    expect(isWithdrawConfirmationValid('WITHDRAW')).toBe(false);
    expect(isWithdrawConfirmationValid('withdraw ')).toBe(true);
    expect(isWithdrawConfirmationValid('no')).toBe(false);
  });

  it('flags active and preparation sessions and notifies admins', async () => {
    const queries = [];
    const pool = {
      query: jest.fn(async (sql, params) => {
        queries.push(sql);
        if (sql.includes('FROM org_foster_parents') && sql.includes('user_id = $2')) {
          return { rows: [{ id: 'rel-1', rules_agreement_at: new Date() }] };
        }
        if (sql.includes('FROM foster_placements') && sql.includes('foster_user_id')) {
          return {
            rows: [
              { id: 'sess-active', status: 'active' },
              { id: 'sess-prep', status: 'preparation' },
              { id: 'sess-done', status: 'returned_to_shelter' },
            ],
          };
        }
        if (sql.includes('UPDATE foster_placements') && sql.includes('flagged_for_admin_review')) {
          return { rows: [] };
        }
        if (sql.includes('FROM organization_users') && sql.includes('user_id')) {
          return { rows: [{ user_id: 'admin-1' }, { user_id: 'admin-2' }] };
        }
        if (sql.includes('INSERT INTO notifications')) {
          return { rows: [] };
        }
        if (sql.includes('UPDATE org_foster_parents') && sql.includes('rules_agreement_at = NULL')) {
          return { rows: [] };
        }
        return { rows: [] };
      }),
    };

    const result = await withdrawFosterAgreement(pool, {
      orgId: 'org-1',
      fosterUserId: 'foster-1',
      actorUserId: 'foster-1',
      fosterDisplayName: 'Jane Foster',
      confirmation: 'withdraw',
    });

    expect(result.status).toBe(200);
    expect(result.flagged_session_ids).toEqual(['sess-active', 'sess-prep']);
    expect(queries.filter((q) => q.includes('INSERT INTO notifications')).length).toBe(2);
  });
});
