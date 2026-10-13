import { describe, expect, it } from '@jest/globals';

import { coordinationBanners } from '../../lib/care/agenda/coordinationCopy.js';

describe('coordination copy (AC-CO-02)', () => {
  it('emits a banner when the same due day spans multiple pets', () => {
    const rows = [
      { petId: 'p1', date: '2026-06-13' },
      { petId: 'p2', date: '2026-06-13' },
    ];
    expect(coordinationBanners(rows)).toEqual([
      { dateKey: '2026-06-13', petIds: ['p1', 'p2'] },
    ]);
  });

  it('does not emit a banner for one pet with multiple items on the same day', () => {
    const rows = [
      { petId: 'p1', date: '2026-06-13' },
      { petId: 'p1', date: '2026-06-13' },
    ];
    expect(coordinationBanners(rows)).toEqual([]);
  });
});
