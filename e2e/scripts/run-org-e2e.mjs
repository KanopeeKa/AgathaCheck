#!/usr/bin/env node
/**
 * Run organisation journey Playwright specs (ci-full-audit / local pre-push; not PR CI).
 */
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { ORG_JOURNEY_SPECS } from './org-e2e-specs.mjs';

const e2eRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

const result = spawnSync(
  'npx',
  ['playwright', 'test', '--project=full', '--max-failures=1', ...ORG_JOURNEY_SPECS],
  {
    cwd: e2eRoot,
    stdio: 'inherit',
    env: {
      ...process.env,
      E2E_BASE_URL: process.env.E2E_BASE_URL ?? 'http://localhost:3000',
    },
  },
);

process.exit(result.status ?? 1);
