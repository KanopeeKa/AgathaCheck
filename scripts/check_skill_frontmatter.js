#!/usr/bin/env node
'use strict';

/**
 * Validate YAML frontmatter in Cursor skill and command markdown files.
 * Fails on parse errors (e.g. unquoted colons in description values).
 */
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const COMMANDS_DIR = path.join(ROOT, '.cursor', 'commands');

function loadYaml() {
  try {
    return require('js-yaml');
  } catch {
    try {
      return require(path.join(ROOT, 'server/node_modules/js-yaml'));
    } catch {
      console.error(
        'check_skill_frontmatter: js-yaml is required. Install backend deps: cd server && npm ci',
      );
      process.exit(1);
    }
  }
}

const yaml = loadYaml();
const TARGETS = [
  path.join(ROOT, '.cursor/skills'),
  path.join(ROOT, '.cursor/commands'),
];

function listSkillFiles(dir) {
  if (!fs.existsSync(dir)) {
    return [];
  }
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      const skill = path.join(full, 'SKILL.md');
      if (fs.existsSync(skill)) {
        files.push(skill);
      }
    } else if (entry.isFile() && entry.name.endsWith('.md')) {
      files.push(full);
    }
  }
  return files;
}

function parseFrontmatter(filePath) {
  const text = fs.readFileSync(filePath, 'utf8');
  const match = text.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  if (!match) {
    throw new Error('missing frontmatter fences');
  }
  return yaml.load(match[1]);
}

let failed = false;
const files = TARGETS.flatMap(listSkillFiles).sort();

for (const file of files) {
  const rel = path.relative(ROOT, file);
  try {
    const data = parseFrontmatter(file);
    if (!data?.name || !data?.description) {
      throw new Error('frontmatter requires name and description');
    }
    const isCommandFile = path.dirname(file) === COMMANDS_DIR;
    if (!isCommandFile && data.name !== path.basename(path.dirname(file))) {
      throw new Error(`name "${data.name}" must match folder ${path.basename(path.dirname(file))}`);
    }
    console.log(`OK ${rel}`);
  } catch (error) {
    failed = true;
    console.error(`FAIL ${rel}: ${error.message}`);
  }
}

if (failed) {
  process.exit(1);
}

console.log(`check_skill_frontmatter: ${files.length} file(s) OK`);
