#!/usr/bin/env node
/**
 * Regenerate the credentials table in docs/e2e/uat-demo-personas.md from seed constants.
 *
 * Usage:
 *   node server/scripts/sync-demo-credentials-doc.js
 *   node server/scripts/sync-demo-credentials-doc.js --check   # exit 1 if out of sync
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { buildDemoCredentialsMarkdownTable } from '../db/seeds/demo-credentials-doc.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const DOC_PATH = path.join(ROOT, 'docs/e2e/uat-demo-personas.md');
const START_MARKER = '<!-- DEMO_CREDENTIALS_TABLE:BEGIN -->';
const END_MARKER = '<!-- DEMO_CREDENTIALS_TABLE:END -->';

function buildDocBlock() {
  const table = buildDemoCredentialsMarkdownTable();
  return `${START_MARKER}\n${table}\n${END_MARKER}`;
}

function syncDoc({ checkOnly = false } = {}) {
  const source = fs.readFileSync(DOC_PATH, 'utf8');
  const block = buildDocBlock();
  const pattern = new RegExp(
    `${START_MARKER}[\\s\\S]*?${END_MARKER}`,
    'm',
  );

  if (!pattern.test(source)) {
    throw new Error(
      `Missing credential markers in ${DOC_PATH} — expected ${START_MARKER}`,
    );
  }

  const updated = source.replace(pattern, block);
  if (updated === source) {
    console.log('sync-demo-credentials-doc: already up to date');
    return false;
  }

  if (checkOnly) {
    console.error(
      'sync-demo-credentials-doc: docs/e2e/uat-demo-personas.md is out of sync',
    );
    console.error('Run: node server/scripts/sync-demo-credentials-doc.js');
    process.exit(1);
  }

  fs.writeFileSync(DOC_PATH, updated);
  console.log(`sync-demo-credentials-doc: updated ${DOC_PATH}`);
  return true;
}

const checkOnly = process.argv.includes('--check');
syncDoc({ checkOnly });
