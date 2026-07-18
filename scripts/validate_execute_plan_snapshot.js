#!/usr/bin/env node
/**
 * Validate execute-plan snapshot JSON and optional drift-classification tests.
 *
 * Usage:
 *   node scripts/validate_execute_plan_snapshot.js <path-to-snapshot.json>
 *   node scripts/validate_execute_plan_snapshot.js --fix-hash <path>
 *   node scripts/validate_execute_plan_snapshot.js --drift-test
 */

'use strict';

const fs = require('fs');
const path = require('path');
const {
  atomicWriteFile,
  computeHash,
  loadSnapshotFromPath,
  runDriftTests,
  validateSnapshot,
  ExecutePlanError,
} = require('./lib/execute_plan_lib');

const REPO_ROOT = path.resolve(__dirname, '..');
const SCHEMA_PATH = path.join(
  REPO_ROOT,
  'docs/agent-efficiency/execute-plan-snapshot.schema.json'
);

function fail(msg) {
  console.error(`validate_execute_plan_snapshot: ${msg}`);
  process.exit(1);
}

function main() {
  const args = process.argv.slice(2);
  if (args.includes('--drift-test')) {
    try {
      runDriftTests();
      console.log('validate_execute_plan_snapshot: drift tests passed');
      process.exit(0);
    } catch (e) {
      fail(e.message);
    }
  }

  const fixHash = args.includes('--fix-hash');
  const fileArg = args.find((a) => !a.startsWith('--'));
  if (!fileArg) {
    console.error(
      'Usage: node scripts/validate_execute_plan_snapshot.js <snapshot.json> [--fix-hash]'
    );
    console.error('       node scripts/validate_execute_plan_snapshot.js --drift-test');
    process.exit(1);
  }

  const filePath = path.resolve(fileArg);
  let obj;
  try {
    obj = loadSnapshotFromPath(filePath);
  } catch (e) {
    if (e && e.code === 'ENOENT') fail(`file not found: ${filePath}`);
    fail(e.message);
  }

  if (fixHash) {
    obj.content_hash = computeHash(obj);
    atomicWriteFile(filePath, `${JSON.stringify(obj, null, 2)}\n`);
    console.log(`validate_execute_plan_snapshot: updated content_hash in ${filePath}`);
  }

  try {
    validateSnapshot(obj, { checkHash: !fixHash });
  } catch (e) {
    fail(e instanceof ExecutePlanError ? e.message : e.message);
  }

  if (!fs.existsSync(SCHEMA_PATH)) {
    console.warn('validate_execute_plan_snapshot: schema file missing (skipped)');
  }

  console.log(`validate_execute_plan_snapshot: OK ${path.relative(REPO_ROOT, filePath)}`);
}

main();
