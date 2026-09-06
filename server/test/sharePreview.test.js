import { buildSharePreviewResponse } from '../lib/sharePreview.js';
import {
  isShareLinkExpired,
  normalizeShareExpiryDays,
} from '../lib/shareLinkPolicy.js';

describe('share link policy', () => {
  it('defaults expiry days to 7 and caps at 90', () => {
    expect(normalizeShareExpiryDays(undefined)).toBe(7);
    expect(normalizeShareExpiryDays(30)).toBe(30);
    expect(normalizeShareExpiryDays(120)).toBe(90);
  });

  it('detects expired links', () => {
    const past = new Date(Date.now() - 1000);
    const future = new Date(Date.now() + 60_000);
    expect(isShareLinkExpired(past)).toBe(true);
    expect(isShareLinkExpired(future)).toBe(false);
    expect(isShareLinkExpired(null)).toBe(true);
  });
});

describe('share preview DTO', () => {
  it('returns only scoped preview fields', () => {
    const payload = buildSharePreviewResponse(
      { status: 'pending', expires_at: new Date('2026-09-13T00:00:00Z') },
      {
        name: 'Buddy',
        species: 'dog',
        breed: 'Lab',
        age: 3,
        date_of_birth: new Date('2023-01-01'),
        photo_path: null,
        color_index: 0,
        insurance: 'secret',
        chip_id: 'chip',
        bio: 'bio',
        vet_id: 'vet-1',
      },
      { first_name: 'Alice', last_name: 'Owner', email: 'alice@example.com' }
    );

    expect(payload.owner).toEqual({ first_name: 'Alice' });
    expect(payload.pet).toMatchObject({
      name: 'Buddy',
      species: 'dog',
      breed: 'Lab',
    });
    expect(payload.pet).not.toHaveProperty('insurance');
    expect(payload.pet).not.toHaveProperty('chipId');
    expect(payload.pet).not.toHaveProperty('bio');
    expect(payload).not.toHaveProperty('vet');
    expect(payload).not.toHaveProperty('health_entries');
  });
});
