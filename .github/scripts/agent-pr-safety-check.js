#!/usr/bin/env node
'use strict';

const { findForbiddenPaths } = require('./agent-safety-lib');

/** Agent implementation PRs include a standalone issue link line (Refs/Fixes #N). */
function isAgentImplementationPr(prBody) {
  if (!prBody) return false;
  return /(?:^|\n)\s*(?:Refs|Fixes|Closes|Resolves)\s+#\d+\s*$/im.test(prBody);
}

async function main() {
  const base = process.env.BASE_SHA;
  const head = process.env.HEAD_SHA;
  const prBody = process.env.PR_BODY || '';

  if (!base || !head) {
    throw new Error('BASE_SHA and HEAD_SHA are required');
  }

  if (!isAgentImplementationPr(prBody)) {
    console.log('Skipping safety gate — not an agent implementation PR (no standalone Refs/Fixes line).');
    return;
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

if (require.main === module) {
  main().catch((error) => {
    console.error(error.message || error);
    process.exit(1);
  });
}

module.exports = { isAgentImplementationPr };
