#!/usr/bin/env node
/**
 * ESLint ratchet on active server/lib, server/services and server/routes (J.2-1).
 *
 * Existing violations are baselined in server/eslint-baseline.json (per file + rule).
 * New violations fail CI; resolved violations fail until --update-baseline shrinks the baseline.
 *
 * Usage:
 *   node scripts/validate_eslint.js
 *   node scripts/validate_eslint.js --init-baseline
 *   node scripts/validate_eslint.js --update-baseline
 *   node scripts/validate_eslint.js --summary
 */
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
const { listActiveServerFiles } = require('./lib/active-server-universe.js');

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, '..');
const DEFAULT_ESLINT_BIN = path.join(REPO_ROOT, 'server/node_modules/eslint/bin/eslint.js');

function fail(msg) {
  console.error(`validate_eslint: ${msg}`);
  process.exit(1);
}

function parseArgs(argv) {
  let mode = 'check';
  let root = REPO_ROOT;
  for (let i = 2; i < argv.length; i++) {
    if (argv[i] === '--init-baseline') mode = 'init';
    else if (argv[i] === '--update-baseline') mode = 'update';
    else if (argv[i] === '--summary') mode = 'summary';
    else if (argv[i] === '--root' && argv[i + 1]) root = path.resolve(argv[++i]);
  }
  return { mode, root };
}

function violationKey(relFile, message) {
  const rule = message.ruleId || 'unknown';
  return `${relFile}::${rule}::${message.line}:${message.column}`;
}

function relFromRepo(root, filePath) {
  const abs = path.resolve(filePath);
  const rel = path.relative(root, abs).replace(/\\/g, '/');
  return rel;
}

export function runEslint(root, files, eslintBin = DEFAULT_ESLINT_BIN, eslintConfig) {
  if (files.length === 0) return [];
  const configPath = eslintConfig || path.join(root, 'server/eslint.config.js');
  let json = '';
  try {
    json = execFileSync(
      process.execPath,
      [
        eslintBin,
        ...files,
        '--config',
        configPath,
        '--format',
        'json',
        '--no-error-on-unmatched-pattern',
      ],
      { cwd: root, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 },
    );
  } catch (err) {
    json = err.stdout?.toString() || '';
    if (!json.trim()) throw err;
  }
  return JSON.parse(json || '[]');
}

export function collectViolations(root, eslintResults) {
  const out = new Map();
  for (const fileResult of eslintResults) {
    const rel = relFromRepo(root, fileResult.filePath);
    for (const msg of fileResult.messages || []) {
      if (msg.severity !== 2) continue;
      const key = violationKey(rel, msg);
      out.set(key, {
        file: rel,
        rule: msg.ruleId || 'unknown',
        line: msg.line,
        column: msg.column,
        message: msg.message,
      });
    }
  }
  return out;
}

function loadBaseline(baselinePath) {
  if (!fs.existsSync(baselinePath)) return { violations: [] };
  const raw = JSON.parse(fs.readFileSync(baselinePath, 'utf8'));
  return {
    _comment: raw._comment,
    violations: Array.isArray(raw.violations) ? raw.violations : [],
  };
}

function baselineKeys(baseline) {
  return new Set(
    baseline.violations.map((v) => violationKey(v.file, { ruleId: v.rule, line: v.line, column: v.column })),
  );
}

function writeBaseline(baselinePath, violations) {
  const sorted = [...violations.values()].sort((a, b) => {
    const ka = `${a.file}::${a.rule}::${a.line}:${a.column}`;
    const kb = `${b.file}::${b.rule}::${b.line}:${b.column}`;
    return ka.localeCompare(kb);
  });
  const payload = {
    _comment:
      'ESLint ratchet for active server/lib, services and routes (J.2-1). Only shrinks: run --update-baseline after fixing a violation.',
    generated_at: new Date().toISOString().slice(0, 10),
    violations: sorted,
  };
  fs.writeFileSync(baselinePath, `${JSON.stringify(payload, null, 2)}\n`);
}

function compare(current, baseline) {
  const base = baselineKeys(baseline);
  const curKeys = new Set(current.keys());
  const newOnes = [...curKeys].filter((k) => !base.has(k));
  const resolved = [...base].filter((k) => !curKeys.has(k));
  return { newOnes, resolved };
}

function main() {
  const { mode, root } = parseArgs(process.argv);
  const eslintBin = fs.existsSync(path.join(root, 'server/node_modules/eslint/bin/eslint.js'))
    ? path.join(root, 'server/node_modules/eslint/bin/eslint.js')
    : DEFAULT_ESLINT_BIN;
  const eslintConfig = path.join(root, 'server/eslint.config.js');
  const baselinePath = path.join(root, 'server/eslint-baseline.json');

  if (!fs.existsSync(eslintBin)) {
    fail('eslint not installed — run npm ci in server/');
  }
  if (!fs.existsSync(eslintConfig)) {
    fail(`missing config ${eslintConfig}`);
  }

  const files = listActiveServerFiles(root);
  const eslintResults = runEslint(root, files, eslintBin, eslintConfig);
  const current = collectViolations(root, eslintResults);

  if (mode === 'summary') {
    console.log(`Active server files linted: ${files.length}`);
    console.log(`ESLint errors (current): ${current.size}`);
    return;
  }

  if (mode === 'init') {
    if (fs.existsSync(baselinePath)) {
      fail('baseline exists — use --update-baseline to shrink it');
    }
    writeBaseline(baselinePath, current);
    console.log(`validate_eslint: wrote baseline with ${current.size} violation(s)`);
    return;
  }

  const baseline = loadBaseline(baselinePath);
  if (!fs.existsSync(baselinePath)) {
    fail('missing server/eslint-baseline.json — run --init-baseline once');
  }

  const { newOnes, resolved } = compare(current, baseline);

  if (mode === 'update') {
    if (newOnes.length > 0) {
      fail(`${newOnes.length} new violation(s) — fix or revert before --update-baseline`);
    }
    writeBaseline(baselinePath, current);
    console.log(
      `validate_eslint: baseline updated (${resolved.length} resolved, ${current.size} remaining)`,
    );
    return;
  }

  if (resolved.length > 0) {
    console.error('validate_eslint: resolved baseline violation(s) — run --update-baseline in this PR:');
    for (const key of resolved.sort()) {
      console.error(`  RESOLVED ${key}`);
    }
    process.exit(1);
  }

  if (newOnes.length > 0) {
    console.error(`validate_eslint: ${newOnes.length} new violation(s) not in baseline:`);
    for (const key of newOnes.sort()) {
      const v = current.get(key);
      console.error(`  NEW ${v.file} [${v.rule}] ${v.message} (${v.line}:${v.column})`);
    }
    process.exit(1);
  }

  console.log(`validate_eslint: OK (${files.length} active server files, ${baseline.violations.length} baselined)`);
}

const isCli =
  process.argv[1] &&
  path.resolve(process.argv[1]) === path.resolve(fileURLToPath(import.meta.url));

if (isCli) {
  main();
}
