import {
  buildCareFamilySuggestionDedupeKey,
  isSuggestionDedupeSuppressedForUser,
} from '../../lib/notifications/suggestionInbox.js';

describe('suggestion dismiss suppression (FR-FB-1)', () => {
  it('isSuggestionDedupeSuppressedForUser respects dismissed row with future expires_at', async () => {
    const dedupeKey = buildCareFamilySuggestionDedupeKey(
      'parasite_prevention',
      's1_missing',
      'pet-1',
    );
    const future = new Date();
    future.setUTCDate(future.getUTCDate() + 10);
    const pool = {
      query: jest.fn(async () => ({
        rows: [{ suggestion_state: 'dismissed', suggestion_expires_at: future }],
      })),
    };
    const suppressed = await isSuggestionDedupeSuppressedForUser(
      pool,
      'user-1',
      dedupeKey,
      new Date(),
    );
    expect(suppressed).toBe(true);
  });

  it('treats expired rows with future suggestion_expires_at as suppressed', async () => {
    const dedupeKey = 'parasite_prevention:s1:pet-1';
    const future = new Date();
    future.setUTCDate(future.getUTCDate() + 25);
    const pool = {
      query: jest.fn(async () => ({
        rows: [{ suggestion_state: 'expired', suggestion_expires_at: future }],
      })),
    };
    expect(
      await isSuggestionDedupeSuppressedForUser(pool, 'user-1', dedupeKey, new Date()),
    ).toBe(true);
  });
});
