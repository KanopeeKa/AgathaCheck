/**
 * Weight undo / completion-date hooks must be wired by the server entry
 * point itself, not only as a side effect of a service import (WEIGHT R2).
 *
 * Two layers, because each catches a different regression:
 * - static: `bin/server.js` imports the hooks module explicitly, so a worker
 *   or refactor that stops loading `weightObservationService` transitively
 *   can't silently bring back "undo leaves the weight linked";
 * - runtime: loading the entry point leaves the registry non-empty
 *   (each Jest test file has its own module registry).
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

import { describe, expect, it } from '@jest/globals';

const serverRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../..');
const read = (rel) => fs.readFileSync(path.join(serverRoot, rel), 'utf8');

describe('weight observation completion hooks', () => {
  it('bin/server.js imports the hooks module explicitly', () => {
    expect(read('bin/server.js')).toMatch(
      /import\s+['"]\.\.\/lib\/care\/observations\/weightObservationCompletionHooks\.js['"]/,
    );
  });

  it('the production start script reaches bin/server.js', () => {
    expect(read('bin/start.js')).toMatch(/from\s+['"]\.\/server\.js['"]/);
  });

  it('are registered once the server entry point is loaded', async () => {
    const hooks = await import('../../../lib/care/observations/observationCompletionHooks.js');
    expect(hooks.observationCompletionHookCount()).toBe(0);

    await import('../../../bin/server.js');

    expect(hooks.observationCompletionHookCount()).toBeGreaterThan(0);
  });
});
