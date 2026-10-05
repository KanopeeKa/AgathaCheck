import { observationCompletionHookCount } from '../../../lib/care/observations/observationCompletionHooks.js';

describe('weight observation completion hooks', () => {
  it('registers hooks when weightObservationCompletionHooks is loaded', async () => {
    await import('../../../lib/care/observations/weightObservationCompletionHooks.js');
    expect(observationCompletionHookCount()).toBeGreaterThan(0);
  });
});
