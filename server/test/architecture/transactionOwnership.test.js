import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

import manifest from '../../../docs/engineering/frozen-domains/manifest.json' with { type: 'json' };

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const serverRoot = path.resolve(__dirname, '../../');

function normalizeRelPath(relativePath) {
  return relativePath.replace(/^server\//, '').replace(/\\/g, '/');
}

/** Phase 4 — replay-safe commands (removed in E.4-10). */
const PHASE4_TEMPORARY_ALLOWLIST = new Set([
  'services/sharing/shareInviteService.js',
  'services/sharing/shareLinkService.js',
  'routes/healthEntries/completeWeightRouter.js',
  'routes/weightEntries.js',
]);

/** PEOPLE server s3 — remove when people-server-7f3b lands. */
const PEOPLE_TEMPORARY_ALLOWLIST = new Set([
  'routes/pets/peopleRelationshipsRouter.js',
]);

/**
 * Care occurrence commands use a dedicated lock primitive (D-CSM-033); migrate with care-schedule work.
 * @see server/lib/care/occurrence/careItemLock.js
 */
const CARE_OCCURRENCE_TRANSACTION_DEFERRED = new Set([
  'lib/care/occurrence/careItemLock.js',
  'lib/care/occurrence/careTick.js',
]);

const ALWAYS_ALLOWED = new Set([
  'lib/db/withTransaction.js',
  'lib/fosterInvite.js',
  'lib/orgPermissions.js',
  ...PHASE4_TEMPORARY_ALLOWLIST,
  ...PEOPLE_TEMPORARY_ALLOWLIST,
  ...CARE_OCCURRENCE_TRANSACTION_DEFERRED,
]);

const BEGIN_PATTERN = /\.query\s*\(\s*['"]BEGIN['"]/s;
const OPTIONAL_TX_PATTERN = /withOptionalTransaction/;

function posixRelative(filePath) {
  return path.relative(serverRoot, filePath).split(path.sep).join('/');
}

function isUnderFrozenServerRoot(relativePath) {
  const rel = normalizeRelPath(relativePath);
  for (const root of manifest.serverRoots || []) {
    const normalized = normalizeRelPath(root);
    if (rel === normalized || rel.startsWith(`${normalized}/`)) {
      return true;
    }
  }
  return false;
}

function collectJsFiles(dir, out = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name === 'node_modules') continue;
      collectJsFiles(full, out);
      continue;
    }
    if (entry.name.endsWith('.js')) out.push(full);
  }
  return out;
}

function scanServerSources() {
  const violations = [];
  const files = collectJsFiles(serverRoot);
  for (const file of files) {
    const rel = normalizeRelPath(posixRelative(file));
    if (rel.startsWith('test/')) continue;
    if (rel.startsWith('scripts/')) continue;
    if (rel.startsWith('db/seeds/')) continue;
    if (isUnderFrozenServerRoot(rel)) continue;
    if (ALWAYS_ALLOWED.has(rel)) continue;

    const source = fs.readFileSync(file, 'utf8');
    if (OPTIONAL_TX_PATTERN.test(source)) {
      violations.push({ file: rel, rule: 'withOptionalTransaction' });
      continue;
    }
    if (BEGIN_PATTERN.test(source)) {
      violations.push({ file: rel, rule: 'hand-written BEGIN' });
    }
  }
  return violations;
}

describe('transaction ownership (E.3)', () => {
  it('active server code uses withTransaction instead of duplicate helpers or BEGIN', () => {
    const violations = scanServerSources();
    expect(violations).toEqual([]);
  });
});
