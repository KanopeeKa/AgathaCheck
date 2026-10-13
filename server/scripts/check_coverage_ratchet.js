#!/usr/bin/env node
/**
 * Backend coverage ratchet (J.1-4): fail when line coverage for an active area
 * drops below the floor recorded in coverage-ratchet.json.
 *
 * Eligible files match Jest collectCoverageFrom (server/collectCoverageFrom.cjs)
 * and scripts/lib/active-server-universe.js. Sources absent from the Jest summary
 * count as 0% covered (unloaded / not instrumented).
 *
 * Usage:
 *   node scripts/check_coverage_ratchet.js [--summary coverage/coverage-summary.json]
 */
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
const { listActiveServerFiles } = require('../../scripts/lib/active-server-universe.js');

const serverRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

function parseArgs(argv) {
  let summaryPath = path.join(serverRoot, 'coverage', 'coverage-summary.json');
  let ratchetPath = path.join(serverRoot, 'coverage-ratchet.json');

  for (let i = 2; i < argv.length; i++) {
    if (argv[i] === '--summary' && argv[i + 1]) {
      summaryPath = path.resolve(serverRoot, argv[++i]);
    } else if (argv[i] === '--ratchet' && argv[i + 1]) {
      ratchetPath = path.resolve(serverRoot, argv[++i]);
    }
  }

  return { summaryPath, ratchetPath };
}

function relServerPath(absPath) {
  const marker = `${path.sep}server${path.sep}`;
  const idx = absPath.lastIndexOf(marker);
  if (idx >= 0) return absPath.slice(idx + marker.length).replace(/\\/g, '/');
  return absPath.replace(/\\/g, '/');
}

function areaForFile(relPath) {
  if (relPath.startsWith('lib/')) return 'lib';
  if (relPath.startsWith('services/')) return 'services';
  if (relPath.startsWith('routes/')) return 'routes';
  return null;
}

function summaryRelPaths(summary) {
  const out = new Set();
  for (const filePath of Object.keys(summary)) {
    if (filePath === 'total') continue;
    out.add(relServerPath(filePath));
  }
  return out;
}

/** Heuristic executable lines when Jest omits a collectCoverageFrom file from the summary. */
function countHeuristicExecutableLines(absPath) {
  const text = fs.readFileSync(absPath, 'utf8');
  let total = 0;
  let block = false;
  for (const raw of text.split('\n')) {
    let s = raw.trim();
    if (!s) continue;
    while (s) {
      if (block) {
        const j = s.indexOf('*/');
        if (j < 0) break;
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
        s.startsWith('import ') ||
        s.startsWith('export ') ||
        s.startsWith('use strict')
      ) {
        break;
      }
      total += 1;
      break;
    }
  }
  return total;
}

export function measureAreas(summary, options = {}) {
  const totals = {
    lib: { covered: 0, total: 0 },
    services: { covered: 0, total: 0 },
    routes: { covered: 0, total: 0 },
  };

  for (const [filePath, metrics] of Object.entries(summary)) {
    if (filePath === 'total') continue;
    const rel = relServerPath(filePath);
    const area = areaForFile(rel);
    if (!area || !metrics?.lines) continue;
    totals[area].total += metrics.lines.total;
    totals[area].covered += metrics.lines.covered;
  }

  const repoRoot = options.repoRoot;
  if (repoRoot) {
    const inSummary = summaryRelPaths(summary);
    for (const rel of listActiveServerFiles(repoRoot)) {
      const serverRel = rel.replace(/^server\//, '');
      const area = areaForFile(serverRel);
      if (!area || inSummary.has(serverRel)) continue;
      const abs = path.join(repoRoot, rel);
      if (!fs.existsSync(abs)) continue;
      const lines = countHeuristicExecutableLines(abs);
      if (lines <= 0) continue;
      totals[area].total += lines;
    }
  }

  const out = {};
  for (const [area, { covered, total }] of Object.entries(totals)) {
    out[area] = {
      lines_percent: total > 0 ? (100 * covered) / total : 0,
      lines_covered: covered,
      lines_total: total,
    };
  }
  return out;
}

function main() {
  const { summaryPath, ratchetPath } = parseArgs(process.argv);

  if (!fs.existsSync(summaryPath)) {
    console.error(`::error::Missing coverage summary: ${summaryPath}`);
    process.exit(1);
  }
  if (!fs.existsSync(ratchetPath)) {
    console.error(`::error::Missing ratchet file: ${ratchetPath}`);
    process.exit(1);
  }

  const summary = JSON.parse(fs.readFileSync(summaryPath, 'utf8'));
  const ratchet = JSON.parse(fs.readFileSync(ratchetPath, 'utf8'));
  const repoRoot = path.resolve(serverRoot, '..');
  const measured = measureAreas(summary, { repoRoot });
  const floors = ratchet.areas || {};

  let failed = false;
  console.log('Backend coverage ratchet (active lib / services / routes):');
  for (const area of ['lib', 'services', 'routes']) {
    const floor = floors[area]?.lines_percent;
    const current = measured[area]?.lines_percent ?? 0;
    if (floor == null) {
      console.error(`::error::No ratchet floor for area ${area}`);
      failed = true;
      continue;
    }
    const ok = current + 0.005 >= floor;
    console.log(
      `  ${area}: ${current.toFixed(2)}% (floor ${floor}%) — ${ok ? 'OK' : 'BELOW FLOOR'}`,
    );
    if (!ok) failed = true;
  }

  if (failed) {
    console.error('::error::Backend coverage dropped below ratchet floor');
    process.exit(1);
  }
}

const isCli =
  process.argv[1] &&
  path.resolve(process.argv[1]) ===
    path.resolve(path.dirname(fileURLToPath(import.meta.url)), 'check_coverage_ratchet.js');

if (isCli) {
  main();
}
