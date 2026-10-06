#!/usr/bin/env node
/**
 * Host cron entrypoint for FR-SG-1 (daily suggestion generation).
 * Example: 15 2 * * * cd /app && node server/scripts/run-suggestion-generation.js
 */
import { createAppPool } from '../lib/db/createPool.js';
import { runSuggestionGenerationNow } from '../lib/suggestions/suggestionGenerationScheduler.js';

const pool = createAppPool();

async function main() {
  const stats = await runSuggestionGenerationNow(pool, { limit: 500 });
  console.log(JSON.stringify({ ok: true, stats }));
}

main()
  .catch((err) => {
    console.error(err);
    process.exitCode = 1;
  })
  .finally(() => pool.end());
