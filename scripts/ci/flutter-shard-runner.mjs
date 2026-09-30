#!/usr/bin/env node
/**
 * Batched Flutter shard runner with crash isolation.
 *
 * One `flutter test` process per batch of files (--concurrency N) instead of one
 * process per file (~5–6 s startup each). Linux `flutter_tester` intermittently
 * segfaults while coverage is collected and the tool can then hang, so every batch
 * runs under a watchdog (no JSON-reporter progress for STALL seconds → kill):
 *
 *   batch exits 0                       → done
 *   batch fails, not killed             → re-run only non-passing files, one per process
 *   batch killed (hang / timeout)       → re-run every file of that batch, one per process
 *
 * A file that fails in isolation fails the shard. A file that failed in the batch but
 * passes alone is reported as a warning (crash/contention), matching the historic
 * per-file semantics. Coverage from batches and isolated runs is merged with
 * scripts/ci/lcov-merge.mjs (no apt lcov).
 *
 * Usage (from flutter_app/): node ../scripts/ci/flutter-shard-runner.mjs <shard>
 * Env: FLUTTER_TEST_CONCURRENCY (default min(4, cpus)), FLUTTER_SHARD_BATCH_SIZE (24),
 *      FLUTTER_SHARD_STALL_SEC (90), FLUTTER_SHARD_BATCH_TIMEOUT_SEC (900),
 *      FLUTTER_SHARD_FILE_TIMEOUT_SEC (300), FLUTTER_BIN (flutter)
 */
import { spawn } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { buildOwnership, isUnder, listTestFiles, loadFrozenTestRoots, loadManifest } from './flutter-shards.mjs';
import { formatLcov, mergeLcovFiles } from './lcov-merge.mjs';

const FLUTTER_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..', 'flutter_app');

const SKIP_TAG_RE = /@Tags\(\[[^\]]*(skip-ci|'frozen'|"frozen")/;

function envInt(name, fallback) {
  const value = Number(process.env[name]);
  return Number.isInteger(value) && value > 0 ? value : fallback;
}

export function toRelative(suitePath) {
  const marker = '/flutter_app/';
  const idx = suitePath.lastIndexOf(marker);
  if (idx >= 0) return suitePath.slice(idx + marker.length);
  return suitePath.replace(/^\.\//, '');
}

/**
 * Parse a `--file-reporter json:` stream.
 * @returns {Map<string, {failed: boolean, done: number, expected: number | null}>}
 */
export function parseReport(text) {
  const suites = new Map(); // suiteID → path
  const stats = new Map(); // path → { failed, done, expected }
  const testSuite = new Map(); // testID → suiteID
  const ensure = (suiteId) => {
    const p = suites.get(suiteId);
    if (!p) return null;
    if (!stats.has(p)) stats.set(p, { failed: false, done: 0, expected: null });
    return stats.get(p);
  };
  for (const line of text.split('\n')) {
    if (!line.trim()) continue;
    let event;
    try {
      event = JSON.parse(line);
    } catch {
      continue;
    }
    switch (event.type) {
      case 'suite':
        suites.set(event.suite.id, toRelative(event.suite.path || ''));
        ensure(event.suite.id);
        break;
      case 'group':
        if (event.group.parentID == null) {
          const s = ensure(event.group.suiteID);
          if (s) s.expected = event.group.testCount;
        }
        break;
      case 'testStart':
        testSuite.set(event.test.id, event.test.suiteID);
        break;
      case 'error': {
        const s = ensure(testSuite.get(event.testID));
        if (s) s.failed = true;
        break;
      }
      case 'testDone': {
        const s = ensure(testSuite.get(event.testID));
        if (!s) break;
        if (event.result !== 'success') s.failed = true;
        if (!event.hidden) s.done += 1;
        break;
      }
      default:
        break;
    }
  }
  return stats;
}

/** Files in `files` that did not provably pass according to `report`. */
export function unprovenFiles(files, report) {
  return files.filter((file) => {
    const s = report.get(file);
    if (!s || s.failed) return true;
    return s.expected != null && s.done < s.expected;
  });
}

export function chunk(list, size) {
  const out = [];
  for (let i = 0; i < list.length; i += size) out.push(list.slice(i, i + size));
  return out;
}

/**
 * Files under a per-file root always run one per `flutter test` process (known coverage-collector
 * crashes); everything else is chunked into batches.
 */
export function planRun(files, perFileRoots, size) {
  const underPerFile = (f) => perFileRoots.some((root) => isUnder(f, root));
  return {
    perFile: files.filter(underPerFile),
    batches: chunk(files.filter((f) => !underPerFile(f)), size),
  };
}

function runFlutter(args, { reportPath, stallSec, timeoutSec }) {
  return new Promise((resolve) => {
    const child = spawn(process.env.FLUTTER_BIN || 'flutter', args, {
      cwd: FLUTTER_ROOT,
      stdio: 'inherit',
      detached: true,
    });
    const started = Date.now();
    let lastSize = -1;
    let lastProgress = Date.now();
    let killedReason = null;
    const kill = (reason) => {
      if (killedReason) return;
      killedReason = reason;
      console.log(`::warning::flutter test ${reason} — killing process group`);
      try {
        process.kill(-child.pid, 'SIGKILL');
      } catch {
        child.kill('SIGKILL');
      }
    };
    const timer = setInterval(() => {
      let size = 0;
      try {
        size = fs.statSync(reportPath).size;
      } catch {
        size = 0;
      }
      if (size !== lastSize) {
        lastSize = size;
        lastProgress = Date.now();
      }
      if (Date.now() - lastProgress > stallSec * 1000) kill(`made no progress for ${stallSec}s (tester hang)`);
      else if (Date.now() - started > timeoutSec * 1000) kill(`exceeded ${timeoutSec}s`);
    }, 5000);
    child.on('exit', (code, signal) => {
      clearInterval(timer);
      resolve({ code: code ?? (signal ? 1 : 0), killed: killedReason });
    });
  });
}

function filterRunnable(files) {
  const runnable = [];
  const skipped = [];
  for (const file of files) {
    const text = fs.readFileSync(path.join(FLUTTER_ROOT, file), 'utf8');
    (SKIP_TAG_RE.test(text) ? skipped : runnable).push(file);
  }
  return { runnable, skipped };
}

async function main(argv) {
  const shard = argv[0];
  const manifest = loadManifest();
  const { byShard } = buildOwnership({ manifest, frozenRoots: loadFrozenTestRoots(), files: listTestFiles() });
  if (!shard || !byShard.has(shard)) {
    console.error(`::error::Unknown Flutter shard '${shard}' (one of: ${[...byShard.keys()].join(', ')})`);
    return 1;
  }
  const { runnable, skipped } = filterRunnable(byShard.get(shard));
  if (runnable.length === 0) {
    console.error(`::error::Flutter shard '${shard}' has no runnable test files`);
    return 1;
  }

  const concurrency = envInt('FLUTTER_TEST_CONCURRENCY', Math.min(4, os.cpus().length || 1));
  const batchSize = envInt('FLUTTER_SHARD_BATCH_SIZE', 24);
  const stallSec = envInt('FLUTTER_SHARD_STALL_SEC', 90);
  const batchTimeout = envInt('FLUTTER_SHARD_BATCH_TIMEOUT_SEC', 900);
  const fileTimeout = envInt('FLUTTER_SHARD_FILE_TIMEOUT_SEC', 300);

  const covDir = path.join(FLUTTER_ROOT, 'coverage');
  fs.rmSync(covDir, { recursive: true, force: true });
  fs.mkdirSync(path.join(covDir, 'parts'), { recursive: true });

  const lcovParts = [];
  const failures = [];
  const recovered = [];
  const { batches, perFile } = planRun(runnable, manifest.perFileRoots, batchSize);
  console.log(
    `Shard ${shard}: ${runnable.length} files — ${batches.length} batch(es) at concurrency ${concurrency}, ${perFile.length} per-file (skipped ${skipped.length} tagged)`,
  );

  let isolatedCount = 0;
  /** Run one file in its own process; returns true when it passed. */
  const runIsolated = async (file) => {
    const n = isolatedCount++;
    const fileReport = path.join(covDir, 'parts', `file-${n}.jsonl`);
    const fileLcov = path.join(covDir, 'parts', `file-${n}.info`);
    console.log(`::group::flutter test ${file} (isolated)`);
    const single = await runFlutter(
      [
        'test',
        file,
        '--concurrency=1',
        '--coverage',
        `--coverage-path=${fileLcov}`,
        '--exclude-tags=integration',
        `--file-reporter=json:${fileReport}`,
      ],
      { reportPath: fileReport, stallSec, timeoutSec: fileTimeout },
    );
    console.log('::endgroup::');
    if (fs.existsSync(fileLcov)) lcovParts.push(fileLcov);
    if (single.code !== 0 || single.killed) {
      console.log(`::error file=flutter_app/${file}::FAIL ${file}${single.killed ? ` (${single.killed})` : ''}`);
      failures.push(file);
      return false;
    }
    return true;
  };

  for (const file of perFile) await runIsolated(file);

  for (const [i, files] of batches.entries()) {
    const reportPath = path.join(covDir, 'parts', `batch-${i}.jsonl`);
    const lcovPath = path.join(covDir, 'parts', `batch-${i}.info`);
    console.log(`::group::flutter test batch ${i + 1}/${batches.length} (${files.length} files)`);
    const result = await runFlutter(
      [
        'test',
        ...files,
        `--concurrency=${concurrency}`,
        '--coverage',
        `--coverage-path=${lcovPath}`,
        '--exclude-tags=integration',
        `--file-reporter=json:${reportPath}`,
      ],
      { reportPath, stallSec, timeoutSec: batchTimeout },
    );
    console.log('::endgroup::');
    if (result.code === 0 && !result.killed && fs.existsSync(lcovPath)) {
      lcovParts.push(lcovPath);
      continue;
    }
    const report = parseReport(fs.existsSync(reportPath) ? fs.readFileSync(reportPath, 'utf8') : '');
    let rerun;
    if (result.killed || !fs.existsSync(lcovPath)) {
      console.log(`::warning::Batch ${i + 1} did not complete (${result.killed || 'no coverage'}) — re-running all ${files.length} files in isolation`);
      rerun = files;
    } else {
      lcovParts.push(lcovPath);
      rerun = unprovenFiles(files, report);
      console.log(`Batch ${i + 1} failed — re-running ${rerun.length} non-passing file(s) in isolation`);
    }
    // Only files the batch actually reported on can be 'recovered' (never-reached files are not).
    const batchFailed = new Set(unprovenFiles(files.filter((f) => report.has(f)), report));
    for (const file of rerun) {
      if ((await runIsolated(file)) && batchFailed.has(file)) {
        console.log(`::warning file=flutter_app/${file}::Failed or crashed in batch, passed in isolation`);
        recovered.push(file);
      }
    }
  }

  const merged = mergeLcovFiles(lcovParts);
  if (merged.size > 0) {
    const text = formatLcov(merged);
    fs.writeFileSync(path.join(covDir, 'lcov.info'), text);
    fs.writeFileSync(path.join(covDir, `lcov.${shard}.info`), text);
    console.log(`Wrote coverage/lcov.${shard}.info (${merged.size} source files)`);
  } else {
    console.log(`::warning::No coverage produced for shard ${shard}`);
  }

  const summary = [
    `### Flutter shard \`${shard}\``,
    '',
    `- files: ${runnable.length} (${batches.length} batch(es) at concurrency ${concurrency}, ${perFile.length} per-file; ${skipped.length} skipped by tag)`,
    `- passed after isolated re-run: ${recovered.length}${recovered.length ? ` — ${recovered.map((f) => `\`${f}\``).join(', ')}` : ''}`,
    `- failed: ${failures.length}${failures.length ? ` — ${failures.map((f) => `\`${f}\``).join(', ')}` : ''}`,
    '',
  ].join('\n');
  if (process.env.GITHUB_STEP_SUMMARY) fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY, `${summary}\n`);
  console.log(summary);
  return failures.length === 0 ? 0 : 1;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === path.resolve(process.argv[1])) {
  main(process.argv.slice(2)).then((code) => process.exit(code));
}
