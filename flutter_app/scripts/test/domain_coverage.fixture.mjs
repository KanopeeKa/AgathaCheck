import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

const require = createRequire(import.meta.url);
const { listEligibleDomainSources, measureDomainCoverage } = require('../domain_coverage_lib.js');

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, '..', '..', '..');
const FLUTTER_ROOT = path.join(REPO_ROOT, 'flutter_app');
const CHECK_SCRIPT = path.join(FLUTTER_ROOT, 'scripts', 'check_domain_coverage.js');
const GENERATE_SCRIPT = path.join(FLUTTER_ROOT, 'scripts', 'generate_coverage_helper.js');

test('missing lcov entry lowers measured domain coverage', () => {
  const domainFiles = listEligibleDomainSources(FLUTTER_ROOT);
  assert.ok(domainFiles.length > 10);

  const sample = domainFiles.find((f) => fs.existsSync(path.join(FLUTTER_ROOT, f)));
  assert.ok(sample);

  const withFile = measureDomainCoverage({
    flutterRoot: FLUTTER_ROOT,
    lcovText: `SF:${path.join(FLUTTER_ROOT, sample)}\nDA:10,1\nend_of_record\n`,
    domainFiles: [sample],
    threshold: 100,
  });

  const withoutFile = measureDomainCoverage({
    flutterRoot: FLUTTER_ROOT,
    lcovText: '',
    domainFiles: [sample],
    threshold: 100,
  });

  assert.ok(withFile.overallPct > withoutFile.overallPct);
  assert.ok(withoutFile.overallPct < 100);
});

test('generate_coverage_helper.js lists every eligible domain import', () => {
  const res = spawnSync(process.execPath, [GENERATE_SCRIPT, '--check'], {
    cwd: FLUTTER_ROOT,
    encoding: 'utf8',
  });
  assert.equal(res.status, 0, res.stderr || res.stdout);
});

test('check_domain_coverage.js passes at recorded threshold on merged lcov', () => {
  const lcovPath = path.join(FLUTTER_ROOT, 'coverage', 'lcov.info');
  if (!fs.existsSync(lcovPath)) {
    return;
  }
  const meta = JSON.parse(
    fs.readFileSync(
      path.join(
        REPO_ROOT,
        'docs/engineering/active-codebase-baseline/flutter-domain-coverage-threshold.json',
      ),
      'utf8',
    ),
  );
  const res = spawnSync(
    process.execPath,
    [CHECK_SCRIPT, '--threshold', String(meta.threshold), '--lcov', lcovPath],
    { cwd: FLUTTER_ROOT, encoding: 'utf8' },
  );
  assert.equal(res.status, 0, res.stderr || res.stdout);
});
