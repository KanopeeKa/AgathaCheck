#!/usr/bin/env node
/**
 * Enforce hand-written file size limits (default 500 lines).
 *
 * Blocking roots: flutter_app/lib, server/routes, server/lib, server/services (D7 ratchet).
 * Allowlist entries in scripts/file-size-allowlist.json carry maxLines, owner, reason and
 * review_date; growth past maxLines fails; expired review_date emits a warning.
 *
 * Usage:
 *   node scripts/check_file_size.js [--limit 500] [--report-only] [--root <repo dir>]
 *
 * Exit codes:
 *   0  all checks pass (or --report-only)
 *   1  violations found
 */

'use strict';

const fs = require('fs');
const path = require('path');
const { listActiveServerFiles, loadManifest, expandFrozenServerRoots, isFrozenServerFile } =
  require('./lib/active-server-universe.js');

const SCAN_ROOTS = ['flutter_app/lib', 'server/routes', 'server/lib', 'server/services'];

const EXCLUDE_DIR_NAMES = new Set(['l10n']);
const EXCLUDE_SUFFIXES = ['.g.dart', '.mocks.dart', '.freezed.dart'];

function parseArgs(argv) {
  let limit = 500;
  let reportOnly = false;
  let root = path.resolve(__dirname, '..');
  for (let i = 2; i < argv.length; i++) {
    if (argv[i] === '--limit' && argv[i + 1]) {
      limit = Number(argv[++i]);
    } else if (argv[i] === '--report-only') {
      reportOnly = true;
    } else if (argv[i] === '--root' && argv[i + 1]) {
      root = path.resolve(argv[++i]);
    }
  }
  if (!Number.isFinite(limit) || limit < 1) {
    throw new Error(`Invalid --limit: ${limit}`);
  }
  return { limit, reportOnly, root };
}

function normalizeAllowlistEntry(value) {
  if (typeof value === 'number') {
    return { maxLines: value, owner: 'unknown', reason: 'legacy numeric allowlist entry', review_date: null };
  }
  return {
    maxLines: value.maxLines,
    owner: value.owner || 'unknown',
    reason: value.reason || '',
    review_date: value.review_date || null,
  };
}

function loadAllowlist(root) {
  const allowlistPath = path.join(root, 'scripts/file-size-allowlist.json');
  if (!fs.existsSync(allowlistPath)) return {};
  const raw = JSON.parse(fs.readFileSync(allowlistPath, 'utf8'));
  const out = {};
  for (const [key, value] of Object.entries(raw)) {
    if (key.startsWith('_')) continue;
    out[key.replace(/\\/g, '/')] = normalizeAllowlistEntry(value);
  }
  return out;
}

function shouldSkip(relPath) {
  const parts = relPath.split('/');
  if (parts.some((p) => EXCLUDE_DIR_NAMES.has(p))) return true;
  return EXCLUDE_SUFFIXES.some((suf) => relPath.endsWith(suf));
}

function collectFiles(repoRoot, scanRoots) {
  const files = [];
  for (const root of scanRoots) {
    const absRoot = path.join(repoRoot, root);
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

function countPhysicalLines(absPath) {
  const text = fs.readFileSync(absPath, 'utf8');
  if (text.length === 0) return 0;
  const matches = text.match(/\n/g);
  const newlines = matches ? matches.length : 0;
  return text.endsWith('\n') ? newlines : newlines + 1;
}

/** Heuristic non-blank / non-comment lines (matches architecture-metrics.py). */
function countHeuristicLines(absPath) {
  const isSql = absPath.endsWith('.sql');
  const text = fs.readFileSync(absPath, 'utf8');
  const ls = text.split('\n');
  let n = 0;
  let block = false;
  for (const raw of ls) {
    let s = raw.trim();
    if (!s) continue;
    while (s) {
      if (block) {
        const j = s.indexOf('*/');
        if (j < 0) {
          s = '';
          break;
        }
        block = false;
        s = s.slice(j + 2).trim();
        continue;
      }
      if (s.startsWith('/*')) {
        block = true;
        s = s.slice(2).trim();
        continue;
      }
      if (
        s.startsWith('//') ||
        s.startsWith('#') ||
        s.startsWith('*') ||
        (isSql && s.startsWith('--'))
      ) {
        s = '';
        break;
      }
      const j = s.indexOf('/*');
      if (j >= 0) {
        if (s.slice(0, j).trim()) n += 1;
        block = true;
        s = s.slice(j + 2).trim();
        continue;
      }
      n += 1;
      break;
    }
  }
  return n;
}

function classifyFlutterFile(rel) {
  if (!rel.startsWith('flutter_app/lib/') || !rel.endsWith('.dart')) return null;
  const norm = rel.replace(/\\/g, '/');
  if (norm.includes('/data/')) return 'data';
  if (norm.includes('/presentation/providers/') || norm.includes('/providers/')) {
    return 'controllers/providers';
  }
  if (norm.includes('/presentation/screens/') || /_screen\.dart$/.test(norm)) return 'screens';
  if (norm.includes('/presentation/widgets/') || norm.includes('/widgets/')) return 'widgets';
  return 'other';
}

function isShelterFamilyServerLib(rel) {
  if (!rel.startsWith('server/lib/')) return false;
  const name = path.posix.basename(rel);
  return (
    /^(org|adoption|foster|fostering)/i.test(name) ||
    ['custodyTransfers.js', 'sessionDetail.js', 'deriveSessionStatus.js'].includes(name)
  );
}

function isFrozenFlutterOrServer(rel, repoRoot) {
  const manifest = loadManifest(repoRoot);
  const frozenFlutter = manifest.sourceRoots || [];
  const frozenServer = expandFrozenServerRoots(manifest.serverRoots || []);
  if (rel.startsWith('flutter_app/')) {
    return frozenFlutter.some((root) => {
      const r = root.replace(/\\/g, '/');
      return rel === r || rel.startsWith(`${r}/`);
    });
  }
  if (rel.startsWith('server/')) {
    return isFrozenServerFile(rel, frozenServer);
  }
  return false;
}

function todayUtc() {
  return new Date().toISOString().slice(0, 10);
}

function main() {
  const { limit, reportOnly, root } = parseArgs(process.argv);
  const allowlist = loadAllowlist(root);
  const violations = [];
  const grandfathered = [];
  const reviewWarnings = [];
  const allFiles = collectFiles(root, SCAN_ROOTS);
  const today = todayUtc();

  for (const rel of allFiles) {
    const abs = path.join(root, rel);
    const lines = countPhysicalLines(abs);
    const entry = allowlist[rel];

    if (entry !== undefined) {
      grandfathered.push({ rel, lines, ceiling: entry.maxLines, entry });
      if (entry.review_date && entry.review_date < today) {
        reviewWarnings.push({
          rel,
          review_date: entry.review_date,
          owner: entry.owner,
        });
      }
      if (lines > entry.maxLines) {
        violations.push({
          rel,
          lines,
          reason: `allowlisted file grew beyond ratchet ceiling ${entry.maxLines}`,
        });
      }
      continue;
    }

    if (lines > limit) {
      violations.push({
        rel,
        lines,
        reason: `exceeds ${limit}-line limit (not on allowlist — split or add only after intentional review)`,
      });
    }
  }

  console.log(
    `File size gate: ${limit} lines (hand-written dart/js under ${SCAN_ROOTS.join(', ')})`,
  );
  console.log(`Grandfathered files: ${grandfathered.length}`);
  console.log(`Scanned files: ${allFiles.length}`);

  const flutterByKind = {};
  for (const rel of allFiles.filter((f) => f.startsWith('flutter_app/lib/') && f.endsWith('.dart'))) {
    const kind = classifyFlutterFile(rel) || 'other';
    if (!flutterByKind[kind]) flutterByKind[kind] = { files: 0, physical: 0, heuristic: 0 };
    const abs = path.join(root, rel);
    flutterByKind[kind].files += 1;
    flutterByKind[kind].physical += countPhysicalLines(abs);
    flutterByKind[kind].heuristic += countHeuristicLines(abs);
  }

  console.log('\nFlutter size summary (physical / heuristic lines by classification):');
  for (const kind of ['screens', 'widgets', 'controllers/providers', 'data', 'other']) {
    const row = flutterByKind[kind];
    if (!row) continue;
    console.log(
      `  ${kind}: ${row.files} files, ${row.physical} physical, ${row.heuristic} heuristic`,
    );
  }

  const serverOffenders = allFiles
    .filter((rel) => rel.startsWith('server/lib/') || rel.startsWith('server/services/'))
    .map((rel) => ({
      rel,
      lines: countPhysicalLines(path.join(root, rel)),
      frozen: isFrozenFlutterOrServer(rel, root) || isShelterFamilyServerLib(rel),
    }))
    .filter((f) => f.lines > limit)
    .sort((a, b) => b.lines - a.lines);

  if (serverOffenders.length > 0) {
    console.log(`\nServer lib/services over ${limit} lines (D7 blocking with allowlist):`);
    for (const f of serverOffenders) {
      const tag = f.frozen ? 'frozen' : 'active';
      console.log(`  ${f.lines} lines [${tag}]  ${f.rel}`);
    }
  }

  if (reviewWarnings.length > 0) {
    console.warn(`\n::warning::${reviewWarnings.length} allowlist review date(s) passed:`);
    for (const w of reviewWarnings.sort((a, b) => a.review_date.localeCompare(b.review_date))) {
      console.warn(`  ${w.rel} (owner ${w.owner}) review_date ${w.review_date}`);
    }
  }

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

module.exports = {
  classifyFlutterFile,
  countHeuristicLines,
  countPhysicalLines,
  loadAllowlist,
  normalizeAllowlistEntry,
};

if (require.main === module) {
  main();
}
