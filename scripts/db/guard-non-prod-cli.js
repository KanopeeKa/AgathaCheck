#!/usr/bin/env node
/**
 * CLI guard for non-prod-only scripts (uat-reset, seed, etc.).
 * Usage: node scripts/db/guard-non-prod.js <operation-name>
 */
import { assertNonProduction } from './guard-non-prod.js';

const operation = process.argv[2] || 'operation';
try {
  assertNonProduction(operation);
} catch (err) {
  console.error(err.message);
  process.exit(1);
}
