#!/usr/bin/env node
/**
 * Enforce @smoke-ci ⊆ @smoke-uat on Playwright test titles.
 *
 * Usage:
 *   node e2e/scripts/check-smoke-tags.mjs
 *
 * Exit 0 when every @smoke-ci title also contains @smoke-uat (or no @smoke-ci yet).
 * Exit 1 on violation.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const TESTS_DIR = path.join(__dirname, '..', 'playwright', 'tests');

const TEST_TITLE_RE = /\btest(?:\.(?:only|skip|fixme))?\s*\(\s*(['"`])([\s\S]*?)\1/g;

function listSpecFiles(dir) {
  /** @type {string[]} */
  const files = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const abs = path.join(dir, entry.name);
    if (entry.isDirectory()) files.push(...listSpecFiles(abs));
    else if (entry.name.endsWith('.spec.ts')) files.push(abs);
  }
  return files;
}

function checkFile(filePath) {
  const rel = path.relative(path.join(__dirname, '..'), filePath).replace(/\\/g, '/');
  const content = fs.readFileSync(filePath, 'utf8');
  /** @type {string[]} */
  const violations = [];

  for (const match of content.matchAll(TEST_TITLE_RE)) {
    const title = match[2];
    if (!title.includes('@smoke-ci')) continue;
    if (!title.includes('@smoke-uat')) {
      violations.push(`${rel}: "${title.trim()}"`);
    }
  }

  return violations;
}

function main() {
  if (!fs.existsSync(TESTS_DIR)) {
    console.error(`check-smoke-tags: tests dir not found: ${TESTS_DIR}`);
    process.exit(1);
  }

  const files = listSpecFiles(TESTS_DIR);
  const violations = files.flatMap(checkFile);
  const hasSmokeCi = files.some((f) => fs.readFileSync(f, 'utf8').includes('@smoke-ci'));

  if (violations.length > 0) {
    console.error('check-smoke-tags: @smoke-ci without @smoke-uat:\n');
    for (const v of violations) console.error(`  - ${v}`);
    process.exit(1);
  }

  if (!hasSmokeCi) {
    console.log('check-smoke-tags: OK (no @smoke-ci tags yet — skeleton passes)');
  } else {
    console.log('check-smoke-tags: OK (@smoke-ci ⊆ @smoke-uat)');
  }
}

main();
