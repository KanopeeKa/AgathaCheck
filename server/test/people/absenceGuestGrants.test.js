import {
  detectGuestAccessWiden,
  userHasActiveAbsenceGuestAccess,
} from '../../lib/people/absenceGuestGrants.js';

describe('detectGuestAccessWiden', () => {
  it('requires confirm when dates extend with active grants', () => {
    const result = detectGuestAccessWiden({
      existing: { ends_on: '2026-10-01' },
      newStartsOn: '2026-09-20',
      newEndsOn: '2026-10-05',
      oldPetIds: ['p1'],
      newPetIds: ['p1'],
      hasActiveGrants: true,
    });
    expect(result.needsConfirm).toBe(true);
    expect(result.extendsDates).toBe(true);
  });

  it('requires confirm when pets are added with active grants', () => {
    const result = detectGuestAccessWiden({
      existing: { ends_on: '2026-10-01' },
      newStartsOn: '2026-09-20',
      newEndsOn: '2026-10-01',
      oldPetIds: ['p1'],
      newPetIds: ['p1', 'p2'],
      hasActiveGrants: true,
    });
    expect(result.needsConfirm).toBe(true);
    expect(result.addedPetIds).toEqual(['p2']);
  });

  it('skips confirm when no active grants', () => {
    const result = detectGuestAccessWiden({
      existing: { ends_on: '2026-10-01' },
      newStartsOn: '2026-09-20',
      newEndsOn: '2026-10-05',
      oldPetIds: ['p1'],
      newPetIds: ['p1', 'p2'],
      hasActiveGrants: false,
    });
    expect(result.needsConfirm).toBe(false);
  });
});

describe('userHasActiveAbsenceGuestAccess', () => {
  it('queries active in-window grants', async () => {
    let capturedSql = '';
    const pool = {
      query: async (sql) => {
        capturedSql = sql;
        return { rows: [{ id: 1 }] };
      },
    };
    const ok = await userHasActiveAbsenceGuestAccess(pool, 'pet-1', 'user-1');
    expect(ok).toBe(true);
    expect(capturedSql).toContain('planned_absence_guest_grants');
    expect(capturedSql).toContain('BETWEEN pa.starts_on AND pa.ends_on');
  });
});
