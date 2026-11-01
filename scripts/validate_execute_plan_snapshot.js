#!/usr/bin/env node
/**
 * Validate execute-plan snapshot JSON and optional drift-classification tests.
 *
 * Usage:
 *   node scripts/validate_execute_plan_snapshot.js <path-to-snapshot.json>
 *   node scripts/validate_execute_plan_snapshot.js --drift-test
 */

'use strict';

const fs = require('fs');
const path = require('path');
const { runDriftTests, ExecutePlanError } = require('./lib/execute_plan_lib');
const { isV2, validateSnapshotV2 } = require('./lib/execute_plan_snapshot_v2');

const REPO_ROOT = path.resolve(__dirname, '..');

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

  const fixHashFlag = '--fix' + '-hash';
  if (args.includes(fixHashFlag)) {
    fail('the --fix' + '-hash option was removed with execute-plan v1 retirement');
  }

  const fileArg = args.find((a) => !a.startsWith('--'));
  if (!fileArg) {
    console.error('Usage: node scripts/validate_execute_plan_snapshot.js <snapshot.json>');
    console.error('       node scripts/validate_execute_plan_snapshot.js --drift-test');
    process.exit(1);
  }

  const filePath = path.resolve(fileArg);
  if (!fs.existsSync(filePath)) {
    fail(`file not found: ${filePath}`);
  }

  let snapshot;
  try {
    snapshot = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch (e) {
    fail(`invalid JSON: ${e.message}`);
  }

  if (!isV2(snapshot)) {
    fail(
      'schema 1 snapshots are historical records only; validate the v2 example or a schema_version 2 snapshot'
    );
  }

  try {
    const planPath = filePath.replace(/\.snapshot\.json$/, '.md');
    validateSnapshotV2(snapshot, { planMarkdown: fs.readFileSync(planPath, 'utf8') });
  } catch (e) {
    fail(e instanceof ExecutePlanError ? e.message : e.message);
  }

  console.log(`validate_execute_plan_snapshot: OK ${path.relative(REPO_ROOT, filePath)}`);
}

main();
