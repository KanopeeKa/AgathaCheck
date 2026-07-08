#!/usr/bin/env node
/**
 * Enforce hand-written file size limits (default 500 lines).
 *
 * Grandfathered files in scripts/file-size-allowlist.json may exceed the limit
 * but must not grow beyond their recorded max (ratchet).
 *
 * Usage:
 *   node scripts/check_file_size.js [--limit 500] [--report-only]
 *
 * Exit codes:
 *   0  all checks pass (or --report-only)
 *   1  violations found
 */

'use strict';

const fs = require('fs');
const path = require('path');

const REPO_ROOT = path.resolve(__dirname, '..');
const ALLOWLIST_PATH = path.join(__dirname, 'file-size-allowlist.json');

const SCAN_ROOTS = [
  'flutter_app/lib',
  'server/routes',
  'server/lib',
];

const EXCLUDE_DIR_NAMES = new Set(['l10n']);
const EXCLUDE_SUFFIXES = ['.g.dart', '.mocks.dart', '.freezed.dart'];

function parseArgs(argv) {
  let limit = 500;
  let reportOnly = false;
  for (let i = 2; i < argv.length; i++) {
    if (argv[i] === '--limit' && argv[i + 1]) {
      limit = Number(argv[++i]);
    } else if (argv[i] === '--report-only') {
      reportOnly = true;
    }
  }
  if (!Number.isFinite(limit) || limit < 1) {
    throw new Error(`Invalid --limit: ${limit}`);
  }
  return { limit, reportOnly };
}

function loadAllowlist() {
  if (!fs.existsSync(ALLOWLIST_PATH)) return {};
  const raw = JSON.parse(fs.readFileSync(ALLOWLIST_PATH, 'utf8'));
  const out = {};
  for (const [key, value] of Object.entries(raw)) {
    if (key.startsWith('_')) continue;
    out[key.replace(/\\/g, '/')] = value;
  }
  return out;
}

function shouldSkip(relPath) {
  const parts = relPath.split('/');
  if (parts.some((p) => EXCLUDE_DIR_NAMES.has(p))) return true;
  return EXCLUDE_SUFFIXES.some((suf) => relPath.endsWith(suf));
}

function collectFiles() {
  const files = [];
  for (const root of SCAN_ROOTS) {
    const absRoot = path.join(REPO_ROOT, root);
    if (!fs.existsSync(absRoot)) continue;
    walk(absRoot, root);
  }
  return files;

  function walk(absDir, relDir) {
    for (const entry of fs.readdirSync(absDir, { withFileTypes: true })) {
      const rel = path.posix.join(relDir, entry.name);
      if (entry.isDirectory()) {
        if (!EXCLUDE_DIR_NAMES.has(entry.name)) {
          walk(path.join(absDir, entry.name), rel);
        }
        continue;
      }
      if (!entry.isFile()) continue;
      if (!/\.(dart|js)$/.test(entry.name)) continue;
      if (shouldSkip(rel)) continue;
      files.push(rel);
    }
  }
}

function countLines(absPath) {
  const text = fs.readFileSync(absPath, 'utf8');
  if (text.length === 0) return 0;
  // Match `wc -l`: newline-terminated lines; no extra line for trailing newline only
  const matches = text.match(/\n/g);
  const newlines = matches ? matches.length : 0;
  return text.endsWith('\n') ? newlines : newlines + 1;
}

function main() {
  const { limit, reportOnly } = parseArgs(process.argv);
  const allowlist = loadAllowlist();
  const violations = [];
  const grandfathered = [];
  const allFiles = collectFiles();

  for (const rel of allFiles) {
    const lines = countLines(path.join(REPO_ROOT, rel));
    const ceiling = allowlist[rel];

    if (ceiling !== undefined) {
      grandfathered.push({ rel, lines, ceiling });
      if (lines > ceiling) {
        violations.push({
          rel,
          lines,
          reason: `grandfathered file grew beyond ratchet ceiling ${ceiling} (was allowed at split time)`,
        });
      }
      continue;
    }

    if (lines > limit) {
      violations.push({
        rel,
        lines,
        reason: `exceeds ${limit}-line limit (not on grandfather allowlist — split or add only after intentional review)`,
      });
    }
  }

  console.log(`File size gate: ${limit} lines (hand-written dart/js under ${SCAN_ROOTS.join(', ')})`);
  console.log(`Grandfathered files: ${grandfathered.length}`);
  console.log(`Scanned files: ${allFiles.length}`);

  if (grandfathered.length > 0) {
    console.log('\nGrandfathered (must shrink over time):');
    for (const g of grandfathered.sort((a, b) => b.lines - a.lines)) {
      console.log(`  ${g.lines} / ${g.ceiling} max  ${g.rel}`);
    }
  }

  if (violations.length > 0) {
    console.error(`\n::error::${violations.length} file size violation(s):`);
    for (const v of violations) {
      console.error(`  [${v.lines} lines] ${v.rel} — ${v.reason}`);
    }
    if (!reportOnly) process.exit(1);
  } else {
    console.log('\nAll file size checks passed.');
  }
}

main();
