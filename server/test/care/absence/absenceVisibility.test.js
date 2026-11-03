import {
  coVisibleAbsencesListSql,
  petProfileAccessSql,
} from '../../../lib/care/absence/absenceVisibility.js';

describe('absenceVisibility SQL helpers', () => {
  it('coVisibleAbsencesListSql scopes to non-declarer absences with profile access', () => {
    const { sql } = coVisibleAbsencesListSql('upcoming', '2026-11-03');
    expect(sql).toContain('pa.user_id != $1');
    expect(sql).toContain('SELECT DISTINCT pa.id');
    expect(sql).toContain('WHERE pa.id IN');
    expect(sql).not.toMatch(/SELECT DISTINCT pa\.\*/);
  });
});
