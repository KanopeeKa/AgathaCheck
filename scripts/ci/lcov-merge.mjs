#!/usr/bin/env node
/**
 * Merge lcov tracefiles without the apt `lcov` package (sums DA hits per SF,
 * recomputes LF/LH). Flutter lcov only carries SF / DA / LF / LH records.
 *
 * Usage:
 *   node scripts/ci/lcov-merge.mjs --out merged.info a.info b.info ...
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

/** @returns {Map<string, Map<number, number>>} SF → (line → hits) */
export function parseLcov(text, into = new Map()) {
  let current = null;
  for (const raw of text.split('\n')) {
    const line = raw.trim();
    if (line.startsWith('SF:')) {
      const file = line.slice(3);
      if (!into.has(file)) into.set(file, new Map());
      current = into.get(file);
    } else if (line.startsWith('DA:') && current) {
      const [lineNo, hits] = line.slice(3).split(',');
      const n = Number(lineNo);
      const h = Number(hits);
      if (Number.isFinite(n) && Number.isFinite(h)) current.set(n, (current.get(n) || 0) + h);
    } else if (line === 'end_of_record') {
      current = null;
    }
  }
  return into;
}

export function formatLcov(records) {
  const out = [];
  for (const file of [...records.keys()].sort()) {
    const lines = records.get(file);
    out.push(`SF:${file}`);
    let hit = 0;
    for (const lineNo of [...lines.keys()].sort((a, b) => a - b)) {
      const hits = lines.get(lineNo);
      if (hits > 0) hit += 1;
      out.push(`DA:${lineNo},${hits}`);
    }
    out.push(`LF:${lines.size}`, `LH:${hit}`, 'end_of_record');
  }
  return out.length ? `${out.join('\n')}\n` : '';
}

export function mergeLcovFiles(files) {
  const records = new Map();
  for (const file of files) {
    if (fs.existsSync(file)) parseLcov(fs.readFileSync(file, 'utf8'), records);
  }
  return records;
}

function main(argv) {
  const outIdx = argv.indexOf('--out');
  if (outIdx === -1 || !argv[outIdx + 1]) {
    console.error('usage: lcov-merge.mjs --out <merged.info> <input.info>...');
    return 1;
  }
  const out = argv[outIdx + 1];
  const inputs = argv.filter((_, i) => i !== outIdx && i !== outIdx + 1);
  const present = inputs.filter((f) => fs.existsSync(f));
  if (present.length === 0) {
    console.error('::error::lcov-merge: no input tracefiles found');
    return 1;
  }
  const records = mergeLcovFiles(present);
  fs.mkdirSync(path.dirname(path.resolve(out)), { recursive: true });
  fs.writeFileSync(out, formatLcov(records));
  console.log(`lcov-merge: ${present.length} tracefile(s) → ${out} (${records.size} source files)`);
  return 0;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === path.resolve(process.argv[1])) {
  process.exit(main(process.argv.slice(2)));
}
