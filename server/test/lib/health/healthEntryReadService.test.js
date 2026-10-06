import { csvCell } from '../../../lib/health/healthEntryCsv.js';
import { exportHealthEntriesCsv } from '../../../lib/health/healthEntryReadService.js';

describe('healthEntryReadService', () => {
  it('csvCell neutralizes formula injection', () => {
    expect(csvCell('=1+1')).toBe("'=1+1");
  });

  it('exportHealthEntriesCsv returns header row', async () => {
    const pool = {
      query: jest.fn(async () => ({ rows: [] })),
    };
    const csv = await exportHealthEntriesCsv(pool, 'user-1');
    expect(csv.startsWith('id,pet_name,name,type')).toBe(true);
    expect(pool.query).toHaveBeenCalledTimes(1);
  });
});
