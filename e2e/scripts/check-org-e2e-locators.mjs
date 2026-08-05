#!/usr/bin/env node
/**
 * Fast static gate: org Flutter navigation changed but E2E page objects were not updated.
 *
 * When a PR touches org Flutter (menus, routes, l10n) without touching org Playwright
 * files, scan org E2E sources for known-removed UI patterns.
 *
 * Usage:
 *   node e2e/scripts/check-org-e2e-locators.mjs
 *   node e2e/scripts/check-org-e2e-locators.mjs --paths-file changed.txt
 *
 * Exit 0 = ok or not applicable; 1 = stale locator patterns found.
 */
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import {
  isOrgE2eTouchPath,
  isOrgE2eTriggerPath,
  ORG_JOURNEY_SPECS,
} from './org-e2e-specs.mjs';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const e2eRoot = path.join(repoRoot, 'e2e');

/** Patterns removed by org UX changes — extend when menus/routes move again. */
const STALE_PATTERNS = [
  {
    id: 'profile-invite-menuitem',
    regex: /getByRole\(\s*['"]menuitem['"]\s*,\s*\{\s*name:\s*['"]Invite Member['"]\s*\}\)/,
    hint: 'Invite via Admin contacts → Add admin (#604), not profile overflow menu.',
  },
  {
    id: 'fosters-standalone-manual-button',
    regex: /getByRole\(\s*['"]button['"]\s*,\s*\{\s*name:\s*['"]Add foster manually['"]\s*\}\)/,
    hint: 'Manage fosters actions moved to overflow menu (#604). Open menu first.',
  },
  {
    id: 'members-route',
    regex: /\/o\/orgs\/\$\{[^}]+\}\/members['"`]/,
    hint: '/members redirects to profile (#604). Use /admin-contacts for member directory.',
  },
];

const SCAN_FILES = [
  ...ORG_JOURNEY_SPECS,
  'playwright/pages/organization-detail.page.ts',
  'playwright/pages/organization-list.page.ts',
  'playwright/pages/organization-form.page.ts',
  'playwright/pages/organization-connections.page.ts',
  'playwright/pages/organization-discover.page.ts',
  'playwright/pages/manage-fosters.page.ts',
];

function readChangedPaths() {
  const pathsFileIdx = process.argv.indexOf('--paths-file');
  if (pathsFileIdx !== -1) {
    const file = process.argv[pathsFileIdx + 1];
    return fs
      .readFileSync(file, 'utf8')
      .split('\n')
      .map((line) => line.trim())
      .filter(Boolean);
  }

  const explicitBase =
    process.env.GITHUB_EVENT_PULL_REQUEST_BASE_SHA?.trim() ||
    process.env.CI_SCOPE_BASE_SHA?.trim() ||
    '';

  if (explicitBase) {
    const diff = spawnSync('git', ['diff', '--name-only', explicitBase, 'HEAD'], {
      cwd: repoRoot,
      encoding: 'utf8',
    });
    if (diff.status === 0) {
      return [
        ...new Set(
          (diff.stdout ?? '')
            .split('\n')
            .map((p) => p.trim())
            .filter(Boolean),
        ),
      ];
    }
  }

  spawnSync('git', ['fetch', 'origin', 'main', '--depth=1', '--quiet'], {
    cwd: repoRoot,
    encoding: 'utf8',
  });

  const mergeBase = spawnSync('git', ['merge-base', 'HEAD', 'origin/main'], {
    cwd: repoRoot,
    encoding: 'utf8',
  });
  const base = mergeBase.stdout.trim() || 'HEAD';
  const diff = spawnSync('git', ['diff', '--name-only', base, 'HEAD'], {
    cwd: repoRoot,
    encoding: 'utf8',
  });
  const unstaged = spawnSync('git', ['diff', '--name-only'], {
    cwd: repoRoot,
    encoding: 'utf8',
  });
  const staged = spawnSync('git', ['diff', '--cached', '--name-only'], {
    cwd: repoRoot,
    encoding: 'utf8',
  });
  const all = [
    ...(diff.stdout?.split('\n') ?? []),
    ...(unstaged.stdout?.split('\n') ?? []),
    ...(staged.stdout?.split('\n') ?? []),
  ];
  return [...new Set(all.map((p) => p.trim()).filter(Boolean))];
}

function scanFile(relPath) {
  const abs = path.join(e2eRoot, relPath);
  if (!fs.existsSync(abs)) return [];
  const lines = fs.readFileSync(abs, 'utf8').split('\n');
  const hits = [];
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    for (const rule of STALE_PATTERNS) {
      if (rule.regex.test(line)) {
        hits.push({ file: relPath, line: i + 1, id: rule.id, hint: rule.hint, text: line.trim() });
      }
    }
  }
  return hits;
}

const changed = readChangedPaths();
const orgFlutterTouched = changed.some(isOrgE2eTriggerPath);
const orgE2eTouched = changed.some(isOrgE2eTouchPath);

if (!orgFlutterTouched) {
  console.log('check-org-e2e-locators: no org Flutter trigger paths in diff — skip');
  process.exit(0);
}

if (orgE2eTouched) {
  console.log('check-org-e2e-locators: org E2E files updated in same diff — skip stale scan');
  process.exit(0);
}

const hits = [];
for (const rel of SCAN_FILES) {
  hits.push(...scanFile(rel));
}

if (hits.length === 0) {
  console.log(
    'check-org-e2e-locators: org Flutter changed without E2E touch — no known stale patterns (run test:org-journey before merge)',
  );
  process.exit(0);
}

console.error('check-org-e2e-locators: stale Playwright locators after org Flutter change\n');
for (const hit of hits) {
  console.error(`  ${hit.file}:${hit.line} [${hit.id}]`);
  console.error(`    ${hit.text}`);
  console.error(`    → ${hit.hint}\n`);
}
console.error('Update org page objects/specs in the same PR, or run: cd e2e && npm run test:org-journey');
process.exit(1);
