import {
  listAllAccessiblePets,
  listOwnedPets,
} from '../../../lib/pets/petCoreQueryService.js';
import { petRowToMap } from '../../../lib/pets/petPresentation.js';

describe('petCoreQueryService', () => {
  it('maps owned pets through petRowToMap', async () => {
    const row = {
      id: 'p1',
      user_id: 'u1',
      name: 'Ada',
      species: 'dog',
      breed: '',
      created_at: new Date(),
      updated_at: new Date(),
    };
    const pool = {
      query: jest.fn(async () => ({ rows: [row] })),
    };
    const pets = await listOwnedPets(pool, 'u1');
    expect(pool.query).toHaveBeenCalledWith(
      'SELECT * FROM pets WHERE user_id = $1 ORDER BY created_at',
      ['u1'],
    );
    expect(pets).toEqual([petRowToMap(row)]);
  });

  it('returns aggregated list from listAllAccessiblePets', async () => {
    const pool = {
      query: jest.fn(async () => ({ rows: [] })),
    };
    await listAllAccessiblePets(pool, 'u1');
    expect(pool.query).toHaveBeenCalledTimes(1);
    expect(String(pool.query.mock.calls[0][0])).toContain('UNION ALL');
  });
});
