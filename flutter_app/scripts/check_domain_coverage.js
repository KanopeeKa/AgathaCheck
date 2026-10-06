#!/usr/bin/env node
/**
 * Enforce minimum line coverage on Flutter domain layer
 * (lib/features/.../domain/... per frozen manifest; missing lcov rows count as 0%).
 *
 * Usage:
 *   node scripts/check_domain_coverage.js [--lcov coverage/lcov.info] [--threshold 70]
 */

const fs = require('fs');
const path = require('path');

const {
  listEligibleDomainSources,
  measureDomainCoverage,
} = require('./domain_coverage_lib');

const flutterRoot = path.resolve(__dirname, '..');

function defaultThreshold() {
  const metaPath = path.join(
    flutterRoot,
    '..',
    'docs/engineering/active-codebase-baseline/flutter-domain-coverage-threshold.json',
  );
  if (fs.existsSync(metaPath)) {
    const meta = JSON.parse(fs.readFileSync(metaPath, 'utf8'));
    if (Number.isFinite(meta.threshold)) return meta.threshold;
  }
  return 70;
}

function parseArgs(argv) {
  let lcovPath = path.join(flutterRoot, 'coverage', 'lcov.info');
  let threshold = defaultThreshold();

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

function main() {
  const { lcovPath, threshold } = parseArgs(process.argv);

  if (!fs.existsSync(lcovPath)) {
    console.error(`::error::Missing lcov file: ${lcovPath}`);
    process.exit(1);
  }

  const domainFiles = listEligibleDomainSources(flutterRoot);
  const lcovText = fs.readFileSync(lcovPath, 'utf8');
  const result = measureDomainCoverage({
    flutterRoot,
    lcovText,
    domainFiles,
    threshold,
  });

  const {
    measuredFiles,
    totalLines,
    hitLines,
    overallPct,
    uncovered,
    missingFromLcov,
  } = result;

  console.log(
    `Flutter domain coverage: ${overallPct.toFixed(1)}% (${hitLines}/${totalLines} lines, ${measuredFiles} files in universe)`,
  );
  if (missingFromLcov.length > 0) {
    console.log(
      `Files absent from lcov (counted as 0%): ${missingFromLcov.length}`,
    );
  }
  console.log(`Threshold: ${threshold}%`);

  if (uncovered.length > 0) {
    console.log('\nDomain files below threshold:');
    for (const entry of uncovered.sort((a, b) => a.pct - b.pct).slice(0, 40)) {
      console.log(
        `  ${entry.file}: ${entry.pct.toFixed(1)}% (${entry.hit}/${entry.total})`,
      );
    }
    if (uncovered.length > 40) {
      console.log(`  … and ${uncovered.length - 40} more`);
    }
  }

  const minFiles = Math.min(20, Math.floor(domainFiles.length * 0.1));
  if (measuredFiles < minFiles) {
    console.error(
      `::error::Too few domain files measured (${measuredFiles} < ${minFiles}) — regenerate coverage helper and merge lcov`,
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
