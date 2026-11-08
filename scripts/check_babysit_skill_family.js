#!/usr/bin/env node
'use strict';

/**
 * CI guard: babysit skill family docs must require resolving every PR review conversation
 * and wiring to scripts/babysit_pr_reviews.js (collect / wait / gate).
 */

const path = require('path');
const { validateBabysitSkillFamily } = require('./lib/babysit_skill_family_policy');

const ROOT = path.resolve(__dirname, '..');

try {
  const result = validateBabysitSkillFamily(ROOT);
  console.log(
    `check_babysit_skill_family: ${result.filesChecked} file(s) OK (resolve-all review conversations)`,
  );
} catch (error) {
  console.error(`check_babysit_skill_family: ${error.message}`);
  process.exit(1);
}
