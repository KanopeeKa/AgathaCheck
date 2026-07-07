#!/usr/bin/env node
/**
 * Enforce minimum line coverage on Flutter domain layer
 * (lib/.../domain/... dart files that have executable lines in lcov).
 *
 * Usage:
 *   node scripts/check_domain_coverage.js [--lcov coverage/lcov.info] [--threshold 65]
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const flutterRoot = path.resolve(__dirname, '..');

function parseArgs(argv) {
  let lcovPath = path.join(flutterRoot, 'coverage', 'lcov.info');
  let threshold = 65;

  for (let i = 2; i < argv.length; i++) {
    if (argv[i] === '--lcov' && argv[i + 1]) {
      lcovPath = path.resolve(flutterRoot, argv[++i]);
    } else if (argv[i] === '--threshold' && argv[i + 1]) {
      threshold = Number(argv[++i]);
    }
  }

  if (!Number.isFinite(threshold) || threshold < 0 || threshold > 100) {
    throw new Error(`Invalid threshold: ${threshold}`);
  }

  return { lcovPath, threshold };
}

function listDomainSources() {
  const output = execSync('find lib -path "*/domain/*.dart"', {
    cwd: flutterRoot,
    encoding: 'utf8',
  });
  return output
    .trim()
    .split('\n')
    .filter(Boolean)
    .sort();
}

function normalizeLcovPath(sf) {
  const marker = 'lib/';
  const idx = sf.lastIndexOf(marker);
  return idx >= 0 ? sf.slice(idx) : sf.replace(/^\.\//, '');
}

function parseLcov(text) {
  const records = new Map();

  for (const rec of text.split('end_of_record')) {
    const sfMatch = rec.match(/^SF:(.+)$/m);
    if (!sfMatch) continue;

    const sf = normalizeLcovPath(sfMatch[1].trim());
    let total = 0;
    let hit = 0;

    for (const line of rec.split('\n')) {
      if (!line.startsWith('DA:')) continue;
      const [, hits] = line.slice(3).split(',');
      total += 1;
      if (Number(hits) > 0) hit += 1;
    }

    records.set(sf, { total, hit });
  }

  return records;
}

function main() {
  const { lcovPath, threshold } = parseArgs(process.argv);

  if (!fs.existsSync(lcovPath)) {
    console.error(`::error::Missing lcov file: ${lcovPath}`);
    process.exit(1);
  }

  const domainFiles = listDomainSources();
  const records = parseLcov(fs.readFileSync(lcovPath, 'utf8'));

  let measuredFiles = 0;
  let totalLines = 0;
  let hitLines = 0;
  const uncovered = [];

  for (const file of domainFiles) {
    const record = records.get(file);
    if (!record || record.total === 0) continue;

    measuredFiles += 1;
    totalLines += record.total;
    hitLines += record.hit;

    const pct = (100 * record.hit) / record.total;
    if (pct < threshold) {
      uncovered.push({ file, pct, hit: record.hit, total: record.total });
    }
  }

  const overallPct = totalLines > 0 ? (100 * hitLines) / totalLines : 0;

  console.log(
    `Flutter domain coverage: ${overallPct.toFixed(1)}% (${hitLines}/${totalLines} lines, ${measuredFiles} files with executable lines)`,
  );
  console.log(`Threshold: ${threshold}%`);

  if (uncovered.length > 0) {
    console.log('\nDomain files below threshold:');
    for (const entry of uncovered.sort((a, b) => a.pct - b.pct)) {
      console.log(
        `  ${entry.file}: ${entry.pct.toFixed(1)}% (${entry.hit}/${entry.total})`,
      );
    }
  }

  if (measuredFiles < 20) {
    console.error(
      '::error::Too few domain files in lcov — install lcov so run_tests_ci.sh can merge per-file coverage',
    );
    process.exit(1);
  }

  if (overallPct + 1e-9 < threshold) {
    console.error(
      `::error::Domain coverage ${overallPct.toFixed(1)}% is below ${threshold}%`,
    );
    process.exit(1);
  }
}

main();
