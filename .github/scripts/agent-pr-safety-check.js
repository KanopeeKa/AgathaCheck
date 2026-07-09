#!/usr/bin/env node
'use strict';

const { findForbiddenPaths } = require('./agent-safety-lib');

async function main() {
  const base = process.env.BASE_SHA;
  const head = process.env.HEAD_SHA;
  if (!base || !head) {
    throw new Error('BASE_SHA and HEAD_SHA are required');
  }

  const { execSync } = require('child_process');
  const diff = execSync(`git diff --name-only ${base} ${head}`, { encoding: 'utf8' });
  const files = diff.split('\n').map((f) => f.trim()).filter(Boolean);
  const forbidden = findForbiddenPaths(files);

  if (forbidden.length > 0) {
    console.error('Forbidden paths modified:');
    for (const file of forbidden) {
      console.error(`  - ${file}`);
    }
    process.exit(1);
  }

  console.log(`Safety gate passed (${files.length} files checked).`);
}

main().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
