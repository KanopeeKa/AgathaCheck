'use strict';

const fs = require('fs');
const path = require('path');
const { SEVERITY } = require('./constants');
const { rel, listFeatureDocs } = require('./paths');
const { parseCanonicalDoc, normalizeCoverageText, isNormativeCoverage } = require('./parse');
const { fileAtRef, workingTreeFile, touchedInDiff } = require('./diff');

const BDD_ROOT = 'flutter_app/test/bdd/features';

function acRowKey(gwt, req) {
  return `${normalizeCoverageText(gwt)}::${normalizeCoverageText(req)}`;
}

function loadFeatureIndex(root) {
  const index = new Map();
  const dir = path.join(root, BDD_ROOT);
  if (!fs.existsSync(dir)) return index;
  for (const file of fs.readdirSync(dir)) {
    if (!file.endsWith('.feature')) continue;
    const text = fs.readFileSync(path.join(dir, file), 'utf8');
    const scenarios = [];
    const tags = [];
    for (const line of text.split('\n')) {
      const tm = line.match(/^\s*@(\S+)/);
      if (tm) tags.push(tm[1].replace(/^@+/, ''));
      const sm = line.match(/^\s*Scenario(?: Outline)?:\s*(.+)$/);
      if (sm) {
        scenarios.push({ title: normalizeCoverageText(sm[1]), tags: [...tags] });
        tags.length = 0;
      }
    }
    index.set(file, scenarios);
  }
  return index;
}

function extractTestNames(filePath) {
  if (!fs.existsSync(filePath)) return new Set();
  const text = fs.readFileSync(filePath, 'utf8');
  const names = new Set();
  const re = /\b(test|it|testWidgets|group|describe)\(\s*['"`]([^'"`]+)['"`]/g;
  let m;
  while ((m = re.exec(text)) !== null) names.add(m[2]);
  return names;
}

function resolveCoverage(root, cov, bddIndex) {
  const c = normalizeCoverageText(cov.replace(/^Coverage:\s*/i, ''));
  const bddM = c.match(/^bdd:\s*([^#@]+)(#(.+)|@(.+))$/i);
  if (bddM) {
    const file = bddM[1].trim();
    const scenarios = bddIndex.get(path.basename(file)) || bddIndex.get(file);
    if (!scenarios) return false;
    if (bddM[3]) {
      const title = normalizeCoverageText(bddM[3]);
      return scenarios.some((s) => s.title === title);
    }
    if (bddM[4]) {
      const tag = bddM[4].replace(/^@+/, '');
      return scenarios.some((s) => s.tags.includes(tag));
    }
  }
  const testM = c.match(/^test:\s*(.+?)(#(.+))?$/i);
  if (testM) {
    const relTest = testM[1].trim();
    const full = path.join(root, relTest);
    if (!fs.existsSync(full)) return false;
    if (!testM[3]) return true;
    const names = extractTestNames(full);
    return names.has(testM[3].trim());
  }
  return true;
}

function runGateTrace(ctx) {
  const findings = [];
  const { root, diff, baseRef, closedIssues } = ctx;
  const bddIndex = loadFeatureIndex(root);

  for (const relPath of [...diff.modified, ...diff.added]) {
    if (!relPath.includes('/features/') || !relPath.endsWith('.md')) continue;
    const headPath = path.join(root, relPath);
    if (!fs.existsSync(headPath)) continue;
    const headDoc = parseCanonicalDoc(headPath, root);
    const baseText = fileAtRef(root, baseRef, relPath);
    let baseKeys = new Set();
    if (baseText) {
      const { parseCanonicalDocFromText } = require('./parse');
      const baseDoc = parseCanonicalDocFromText(baseText, root);
      if (baseDoc.acceptance) {
        for (const row of baseDoc.acceptance.rows) {
          baseKeys.add(acRowKey(row.cells[0], row.cells[1]));
        }
      }
    }
    if (!headDoc.acceptance) continue;
    for (const row of headDoc.acceptance.rows) {
      const key = acRowKey(row.cells[0], row.cells[1]);
      const changed = !baseKeys.has(key);
      if (!changed) continue;
      const cov = row.cells[2] || '';
      if (!isNormativeCoverage(cov, { allowLegacy: false })) {
        findings.push({
          ruleId: 'R-T1',
          severity: SEVERITY.BLOCK,
          file: relPath,
          line: row.lineNum,
          message:
            'Coverage must use bdd:/test:/none — #n normative forms (see standards §3.3).',
        });
        continue;
      }
      if (/^TBD\s*[—-]\s*consolidate$/i.test(normalizeCoverageText(cov))) {
        findings.push({
          ruleId: 'R-T2',
          severity: SEVERITY.BLOCK,
          file: relPath,
          line: row.lineNum,
          message: 'TBD — consolidate is allowed on untouched rows only.',
        });
        continue;
      }
      if (/^bdd:|^test:/i.test(normalizeCoverageText(cov)) && !resolveCoverage(root, cov, bddIndex)) {
        findings.push({
          ruleId: 'R-T3',
          severity: SEVERITY.BLOCK,
          file: relPath,
          line: row.lineNum,
          message: 'Coverage bdd:/test: reference does not resolve.',
        });
      }
    }
  }

  if (closedIssues) {
    for (const filePath of listFeatureDocs(root)) {
      const relPath = rel(root, filePath);
      const doc = parseCanonicalDoc(filePath, root);
      if (!doc.acceptance) continue;
      for (const row of doc.acceptance.rows) {
        const m = String(row.cells[2] || '').match(/#\s*(\d+)/);
        if (m && closedIssues.has(Number(m[1]))) {
          findings.push({
            ruleId: 'R-T4',
            severity: SEVERITY.REPORT,
            file: relPath,
            line: row.lineNum,
            message: `AC references closed issue #${m[1]}.`,
          });
        }
      }
    }
  }
  return findings;
}

function buildDomainReport(root, baseline) {
  const { isBaselineFeature } = require('./baseline');
  const bddIndex = loadFeatureIndex(root);
  const byDomain = {};
  let allFeatures = 0;
  let nonBaseline = 0;
  for (const filePath of listFeatureDocs(root)) {
    const relPath = rel(root, filePath);
    const domain = relPath.split('/')[2] || 'unknown';
    byDomain[domain] = byDomain[domain] || {
      ac_total: 0,
      ac_traced: 0,
      ac_untraced: 0,
      req_live: 0,
      req_covered: 0,
    };
    allFeatures += 1;
    const inBase = isBaselineFeature(baseline, relPath);
    if (!inBase) nonBaseline += 1;
    const doc = parseCanonicalDoc(filePath, root);
    const liveReqs = new Set();
    if (doc.requirements) {
      for (const row of doc.requirements.rows) {
        if (row.cells[2] === 'Live') {
          liveReqs.add(row.cells[0]);
          byDomain[domain].req_live += 1;
        }
      }
    }
    const coveredLive = new Set();
    if (doc.acceptance) {
      for (const row of doc.acceptance.rows) {
        byDomain[domain].ac_total += 1;
        const cov = row.cells[2] || '';
        const traced =
          /^bdd:|^test:/i.test(normalizeCoverageText(cov)) &&
          resolveCoverage(root, cov, bddIndex);
        if (traced) byDomain[domain].ac_traced += 1;
        else byDomain[domain].ac_untraced += 1;
        if (traced) {
          for (const rid of String(row.cells[1] || '').split(',')) {
            if (liveReqs.has(rid.trim())) coveredLive.add(rid.trim());
          }
        }
      }
    }
    byDomain[domain].req_covered += coveredLive.size;
  }
  return { byDomain, canonical_ratio: allFeatures ? nonBaseline / allFeatures : 0 };
}

function baselineReportMarkdown(root, baseline) {
  const { byDomain, canonical_ratio } = buildDomainReport(root, baseline);
  const lines = [
    '',
    '| Domain | ac_total | ac_traced_pct | req_live | req_covered_pct |',
    '| --- | ---: | ---: | ---: | ---: |',
  ];
  for (const [domain, m] of Object.entries(byDomain).sort()) {
    const tp = m.ac_total ? Math.round((100 * m.ac_traced) / m.ac_total) : 0;
    const cp = m.req_live ? Math.round((100 * m.req_covered) / m.req_live) : 0;
    lines.push(`| ${domain} | ${m.ac_total} | ${tp}% | ${m.req_live} | ${cp}% |`);
  }
  lines.push(`\ncanonical_ratio: ${(canonical_ratio * 100).toFixed(1)}%`);
  return lines.join('\n');
}

module.exports = { runGateTrace, buildDomainReport, resolveCoverage, loadFeatureIndex, baselineReportMarkdown };
