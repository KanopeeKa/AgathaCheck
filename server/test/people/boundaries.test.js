import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

import { describe, expect, it } from '@jest/globals';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../..');

const PEOPLE_WRITE_RE = /(?:INSERT\s+INTO|UPDATE|DELETE\s+FROM)\s+people_(?:contacts|contact_roles|contact_private_notes|directories)\b/gi;

const SCAN_ROOTS = [
  'server/routes',
  'server/lib',
  'server/bin',
];

const EXCLUDED_DIR_PREFIXES = [
  'server/lib/people/',
  'server/test/',
  'server/scripts/',
  'server/db/',
];

const SQL_FILE_ALLOWLIST = new Set([
  'server/lib/households/authz.js',
]);

const IMPORT_ALLOWLIST = new Set([
  'server/routes/vets.js',
  'server/routes/pets/coreRouter.js',
  'server/routes/pets/peopleRelationshipsRouter.js',
  'server/routes/careContext/plannedAbsencesRouter.js',
  'server/routes/careContext/plannedAbsenceCarerInviteRoutes.js',
  'server/routes/careContext/plannedAbsenceStore.js',
  'server/scripts/migrations/073_people_vet_backfill.js',
  'server/scripts/migrations/075_planned_absence_carer_contacts.js',
  'server/scripts/reconcilePeopleVets.js',
  'server/db/seeds/helpers/people-vet-contact.js',
  'server/db/seeds/scenarios/health-care.js',
]);

const PEOPLE_DEEP_IMPORT_RE = /from\s+['"](?:\.\.\/)*lib\/people\/(?!index\.js)([^'"]+)['"]/g;

function walkJsFiles(dir, relBase = '') {
  const abs = path.join(repoRoot, relBase || dir);
  if (!fs.existsSync(abs)) return [];
  const entries = fs.readdirSync(abs, { withFileTypes: true });
  const files = [];
  for (const ent of entries) {
    const rel = path.join(relBase || dir, ent.name).replace(/\\/g, '/');
    if (ent.isDirectory()) {
      if (rel.includes('node_modules')) continue;
      files.push(...walkJsFiles(dir, rel));
    } else if (ent.name.endsWith('.js')) {
      files.push(rel);
    }
  }
  return files;
}

function isExcluded(relPath) {
  return EXCLUDED_DIR_PREFIXES.some((prefix) => relPath.startsWith(prefix));
}

function collectScanFiles() {
  const files = new Set();
  for (const root of SCAN_ROOTS) {
    for (const f of walkJsFiles(root, root)) {
      if (!isExcluded(f)) files.add(f);
    }
  }
  return [...files].sort();
}

describe('People domain boundaries (s1)', () => {
  it('people_contacts INSERT appears only in contactsRepo.js', () => {
    const peopleLibFiles = walkJsFiles('server/lib/people', 'server/lib/people');
    const insertHits = [];
    for (const rel of [...collectScanFiles(), ...peopleLibFiles]) {
      if (SQL_FILE_ALLOWLIST.has(rel)) continue;
      const content = fs.readFileSync(path.join(repoRoot, rel), 'utf8');
      if (/INSERT\s+INTO\s+people_contacts\b/i.test(content)) {
        insertHits.push(rel);
      }
    }
    const unique = [...new Set(insertHits)].sort();
    expect(unique.every((f) => f.startsWith('server/lib/people/contactsRepo'))).toBe(true);
    expect(unique).toContain('server/lib/people/contactsRepoSql.js');
  });

  it('no raw people table writes outside server/lib/people/', () => {
    const violations = [];
    for (const rel of collectScanFiles()) {
      if (SQL_FILE_ALLOWLIST.has(rel)) continue;
      const content = fs.readFileSync(path.join(repoRoot, rel), 'utf8');
      const matches = content.match(PEOPLE_WRITE_RE);
      if (matches?.length) violations.push({ file: rel, count: matches.length });
    }
    expect(violations).toEqual([]);
  });

  it('production code imports people only via index.js (allowlisted transitional)', () => {
    const violations = [];
    for (const rel of collectScanFiles()) {
      if (IMPORT_ALLOWLIST.has(rel)) continue;
      const content = fs.readFileSync(path.join(repoRoot, rel), 'utf8');
      const matches = [...content.matchAll(PEOPLE_DEEP_IMPORT_RE)];
      for (const m of matches) {
        violations.push(`${rel} -> lib/people/${m[1]}`);
      }
    }
    expect(violations).toEqual([]);
  });
});
