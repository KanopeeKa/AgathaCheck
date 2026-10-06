'use strict';

const fs = require('fs');
const path = require('path');
const { finding } = require('./findings');
const { parseFrontmatter } = require('./yaml');
const { isCanonicalFeatureDoc, normalizeRepoPath } = require('./paths');
const { readWorkingFile, readFileAtRef } = require('./git');
const { parseAcceptanceCriteria } = require('./parse-md');
const { COVERAGE_RE } = require('./constants');

function normalizeCoverage(cov) {
  return String(cov || '')
    .trim()
    .replace(/\s+/g, ' ')
    .replace(/'/g, "'");
}

function gateTrace(ctx) {
  const findings = [];
  const { root, base, diffFiles, bddIndex, testIndex } = ctx;

  for (const rel of diffFiles) {
    if (!isCanonicalFeatureDoc(rel)) {
      continue;
    }
    const normalized = normalizeRepoPath(rel);
    const headText = readWorkingFile(root, normalized);
    const baseText = readFileAtRef(root, base, normalized);
    if (!headText) {
      continue;
    }

    const baseBody = baseText ? stripFm(baseText) : '';
    const headBody = stripFm(headText);
    const baseRows = new Map(
      parseAcceptanceCriteria(baseBody).map((r) => [rowKey(r), r.coverage]),
    );
    const headRows = parseAcceptanceCriteria(headBody);

    for (const row of headRows) {
      const cov = normalizeCoverage(row.coverage);
      const key = rowKey(row);
      const prev = baseRows.has(key) ? normalizeCoverage(baseRows.get(key)) : null;
      const changed = !prev || prev !== cov;
      const legacyTbd = /TBD\s*—\s*consolidate/i.test(cov);

      if (legacyTbd && !changed) {
        continue;
      }
      if (legacyTbd && changed) {
        findings.push(
          finding('R-T2', 'BLOCK', 'New/changed AC still has TBD coverage', normalized),
        );
        continue;
      }
      if (!cov || /^TBD/i.test(cov)) {
        if (changed) {
          findings.push(
            finding('R-T2', 'BLOCK', 'AC row missing coverage wire format', normalized),
          );
        }
        continue;
      }

      if (!COVERAGE_RE.test(cov)) {
        if (changed) {
          findings.push(
            finding('R-T2', 'BLOCK', `Invalid coverage format: ${cov}`, normalized),
          );
        }
        continue;
      }

      const covFindings = validateCoverageRef(cov, bddIndex, testIndex, normalized);
      for (const f of covFindings) {
        if (changed || !legacyTbd) {
          findings.push(f);
        }
      }
    }
  }

  return findings;
}

function rowKey(row) {
  return `${row.gwt}::${row.requirement}`;
}

function stripFm(text) {
  return text.replace(/^---\r?\n[\s\S]*?\r?\n---/, '');
}

function validateCoverageRef(cov, bddIndex, testIndex, file) {
  const findings = [];
  const c = normalizeCoverage(cov);
  if (/^bdd:/i.test(c)) {
    const rest = c.replace(/^bdd:\s*/i, '');
    if (rest.includes('@')) {
      const tag = rest.match(/@(\S+)/)?.[1];
      if (tag && !bddIndex.tags.has(`@${tag}`) && !bddIndex.tags.has(tag)) {
        findings.push(
          finding('R-T3', 'BLOCK', `BDD tag not found: ${tag}`, file),
        );
      }
      return findings;
    }
    const [featPart, titlePart] = rest.split('#');
    const feat = featPart.trim();
    const title = titlePart ? normalizeApostrophe(titlePart.trim()) : '';
    const scenarios = bddIndex.scenarios.get(feat) || bddIndex.scenarios.get(path.basename(feat));
    if (!scenarios) {
      findings.push(finding('R-T3', 'BLOCK', `BDD feature not found: ${feat}`, file));
      return findings;
    }
    if (title) {
      const ok = scenarios.some((s) => normalizeApostrophe(s) === title);
      if (!ok) {
        findings.push(
          finding('R-T3', 'BLOCK', `BDD scenario title not found: ${title}`, file),
        );
      }
    }
    return findings;
  }

  if (/^test:/i.test(c)) {
    const rest = c.replace(/^test:\s*/i, '');
    const [filePart, namePart] = rest.split('#');
    const testFile = filePart.trim();
    const name = namePart ? namePart.trim() : '';
    const names = testIndex.get(testFile);
    if (!names) {
      findings.push(finding('R-T3', 'BLOCK', `Test file not found: ${testFile}`, file));
      return findings;
    }
    if (name && !names.has(name)) {
      const partial = [...names].some((n) => n.includes(name));
      if (partial && !names.has(name)) {
        findings.push(
          finding('R-T3', 'BLOCK', `Test name must match exactly: ${name}`, file),
        );
      } else if (!partial) {
        findings.push(
          finding('R-T3', 'BLOCK', `Test name not found: ${name}`, file),
        );
      }
    }
  }

  return findings;
}

function normalizeApostrophe(s) {
  return s.replace(/['']/g, "'");
}

function buildBddIndex(root) {
  const dir = path.join(root, 'flutter_app/test/bdd/features');
  const scenarios = new Map();
  const tags = new Set();
  if (!fs.existsSync(dir)) {
    return { scenarios, tags };
  }
  for (const name of fs.readdirSync(dir)) {
    if (!name.endsWith('.feature')) {
      continue;
    }
    const text = fs.readFileSync(path.join(dir, name), 'utf8');
    const scen = [];
    for (const line of text.split('\n')) {
      const sm = line.match(/^\s*Scenario(?: Outline)?:\s*(.+)/);
      if (sm) {
        scen.push(sm[1].trim());
      }
      for (const tm of line.matchAll(/@(\S+)/g)) {
        tags.add(`@${tm[1]}`);
        tags.add(tm[1]);
      }
    }
    scenarios.set(name, scen);
    scenarios.set(`flutter_app/test/bdd/features/${name}`, scen);
  }
  return { scenarios, tags };
}

function buildTestIndex(root) {
  const index = new Map();
  walkTests(path.join(root, 'flutter_app/test'), root, 'flutter_app/test', index);
  walkTests(path.join(root, 'server/test'), root, 'server/test', index);
  return index;
}

function walkTests(absDir, root, prefix, index) {
  if (!fs.existsSync(absDir)) {
    return;
  }
  for (const entry of fs.readdirSync(absDir, { withFileTypes: true })) {
    const full = path.join(absDir, entry.name);
    if (entry.isDirectory()) {
      walkTests(full, root, prefix, index);
    } else if (entry.name.endsWith('.dart') || entry.name.endsWith('.test.js')) {
      const rel = `${prefix}/${path.relative(path.join(root, prefix), full)}`.replace(/\\/g, '/');
      const text = fs.readFileSync(full, 'utf8');
      const names = new Set();
      for (const m of text.matchAll(/\b(?:test|it)\s*\(\s*['"`]([^'"`]+)['"`]/g)) {
        names.add(m[1]);
      }
      index.set(rel, names);
      index.set(path.basename(rel), names);
    }
  }
}

module.exports = {
  gateTrace,
  buildBddIndex,
  buildTestIndex,
  validateCoverageRef,
};
