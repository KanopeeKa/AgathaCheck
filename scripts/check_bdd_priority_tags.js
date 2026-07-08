#!/usr/bin/env node
/**
 * Validates (and optionally applies) @P0/@P1/@P2 priority tags on Gherkin
 * scenarios in flutter_app/test/bdd/features/*.feature.
 *
 * Usage:
 *   node scripts/check_bdd_priority_tags.js [--apply]
 *
 * Exit codes:
 *   0  every scenario has exactly one correct priority tag
 *   1  missing, duplicate, or mismatched tags (when not --apply)
 */

'use strict';

const fs = require('fs');
const path = require('path');

const REPO_ROOT = path.resolve(__dirname, '..');
const FEATURES_DIR = path.join(REPO_ROOT, 'flutter_app', 'test', 'bdd', 'features');
const MAP_PATH = path.join(__dirname, 'bdd-priority-tag-map.json');

const PRIORITY_TAGS = ['@P0', '@P1', '@P2'];
const PRIORITY_TAG_RE = /^\s*@(P0|P1|P2)\s*$/;

function parseArgs(argv) {
  return { apply: argv.includes('--apply') };
}

function loadMap() {
  const raw = JSON.parse(fs.readFileSync(MAP_PATH, 'utf8'));
  const map = new Map();
  for (const [file, scenarios] of Object.entries(raw)) {
    for (const [title, priority] of Object.entries(scenarios)) {
      map.set(`${file}\0${title}`, priority);
    }
  }
  return { raw, map };
}

function extractPriorityTag(line) {
  const m = line.match(PRIORITY_TAG_RE);
  return m ? `@${m[1]}` : null;
}

function scenarioIndent(line) {
  const m = line.match(/^(\s*)Scenario:/);
  return m ? m[1].length : 2;
}

function processFeatureFile(filePath, fileName, priorityMap, apply) {
  const lines = fs.readFileSync(filePath, 'utf8').split('\n');
  const issues = [];
  const changes = [];
  let modified = false;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const scenarioMatch = line.match(/^(\s*)Scenario:\s*(.+)/);
    if (!scenarioMatch) continue;

    const title = scenarioMatch[2].trim();
    const indent = scenarioMatch[1];
    const expected = priorityMap.get(`${fileName}\0${title}`);

    if (!expected) {
      issues.push({ file: fileName, title, kind: 'unmapped' });
      continue;
    }

    const expectedTag = `@${expected}`;
    const prevLine = i > 0 ? lines[i - 1] : '';
    const foundTag = extractPriorityTag(prevLine);

    if (!foundTag) {
      issues.push({ file: fileName, title, kind: 'missing', expected: expectedTag });
      if (apply) {
        lines.splice(i, 0, `${indent}${expectedTag}`);
        changes.push({ file: fileName, title, action: 'inserted', tag: expectedTag });
        modified = true;
        i += 1;
      }
      continue;
    }

    if (foundTag !== expectedTag) {
      issues.push({
        file: fileName,
        title,
        kind: 'mismatch',
        expected: expectedTag,
        found: foundTag,
      });
      if (apply) {
        lines[i - 1] = `${indent}${expectedTag}`;
        changes.push({ file: fileName, title, action: 'corrected', tag: expectedTag });
        modified = true;
      }
      continue;
    }

    // Guard against duplicate priority tags on adjacent lines above the scenario.
    if (i > 1) {
      const prevPrevTag = extractPriorityTag(lines[i - 2]);
      if (prevPrevTag) {
        issues.push({
          file: fileName,
          title,
          kind: 'duplicate',
          found: `${prevPrevTag}, ${foundTag}`,
        });
      }
    }
  }

  if (apply && modified) {
    fs.writeFileSync(filePath, lines.join('\n'), 'utf8');
  }

  return { issues, changes, modified };
}

function countPriorities(raw) {
  const counts = { P0: 0, P1: 0, P2: 0 };
  for (const scenarios of Object.values(raw)) {
    for (const priority of Object.values(scenarios)) {
      counts[priority] += 1;
    }
  }
  return counts;
}

function main() {
  const { apply } = parseArgs(process.argv.slice(2));
  const { raw, map } = loadMap();

  const featureFiles = fs
    .readdirSync(FEATURES_DIR)
    .filter((f) => f.endsWith('.feature'))
    .sort();

  const allIssues = [];
  const allChanges = [];
  const changedFiles = new Set();

  for (const fileName of featureFiles) {
    const filePath = path.join(FEATURES_DIR, fileName);
    const { issues, changes, modified } = processFeatureFile(
      filePath,
      fileName,
      map,
      apply,
    );
    allIssues.push(...issues);
    allChanges.push(...changes);
    if (modified) changedFiles.add(fileName);
  }

  const counts = countPriorities(raw);
  const totalMapped = counts.P0 + counts.P1 + counts.P2;

  console.log('BDD priority tag check');
  console.log(`  Map: ${MAP_PATH}`);
  console.log(`  Features: ${featureFiles.length} files, ${totalMapped} mapped scenarios`);
  console.log(`  Priority tiers: P0=${counts.P0}, P1=${counts.P1}, P2=${counts.P2}`);

  if (apply) {
    console.log(`\n  Applied tags to ${changedFiles.size} file(s):`);
    for (const f of [...changedFiles].sort()) {
      console.log(`    - ${f}`);
    }
  }

  const blockingIssues = apply
    ? allIssues.filter((i) => i.kind === 'unmapped' || i.kind === 'duplicate')
    : allIssues;

  if (blockingIssues.length > 0) {
    console.log(`\n  Issues (${blockingIssues.length}):`);
    for (const issue of blockingIssues) {
      if (issue.kind === 'missing') {
        console.log(`    [missing] ${issue.file} — "${issue.title}" (expected ${issue.expected})`);
      } else if (issue.kind === 'mismatch') {
        console.log(
          `    [mismatch] ${issue.file} — "${issue.title}" (expected ${issue.expected}, found ${issue.found})`,
        );
      } else if (issue.kind === 'duplicate') {
        console.log(
          `    [duplicate] ${issue.file} — "${issue.title}" (${issue.found})`,
        );
      } else if (issue.kind === 'unmapped') {
        console.log(`    [unmapped] ${issue.file} — "${issue.title}"`);
      }
    }
    process.exit(1);
  }

  if (!apply) {
    console.log('\n  All scenarios have correct priority tags.');
  } else if (changedFiles.size === 0) {
    console.log('\n  No file changes needed.');
  }

  process.exit(0);
}

main();
