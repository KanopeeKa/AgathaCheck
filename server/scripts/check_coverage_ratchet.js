#!/usr/bin/env node
/**
 * Backend coverage ratchet (J.1-4): fail when line coverage for an active area
 * drops below the floor recorded in coverage-ratchet.json.
 *
 * Usage:
 *   node scripts/check_coverage_ratchet.js [--summary coverage/coverage-summary.json]
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

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

export function measureAreas(summary) {
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
  const measured = measureAreas(summary);
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
