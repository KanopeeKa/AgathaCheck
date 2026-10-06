'use strict';

const fs = require('fs');
const path = require('path');
const {
  REQ_HEADER,
  AC_HEADER,
  DEC_HEADER,
  REQ_STATUSES,
  DEC_STATUSES_LIVE,
  DEC_STATUSES_SUPER,
} = require('./constants');

function loadYaml(root) {
  try {
    return require('js-yaml');
  } catch {
    try {
      return require(path.join(root, 'server/node_modules/js-yaml'));
    } catch {
      try {
        return require(path.resolve(__dirname, '../../../server/node_modules/js-yaml'));
      } catch {
        throw new Error('js-yaml is required. Install backend deps: cd server && npm ci');
      }
    }
  }
}

function parseFrontmatter(text) {
  if (!text.startsWith('---\n')) return { meta: {}, body: text };
  const end = text.indexOf('\n---\n', 4);
  if (end === -1) return { meta: {}, body: text };
  const raw = text.slice(4, end);
  const body = text.slice(end + 5);
  return { raw, body };
}

function parseDocText(text, root) {
  const { raw, body } = parseFrontmatter(text);
  let meta = {};
  if (raw) {
    const yaml = loadYaml(root);
    try {
      meta = yaml.load(raw) || {};
    } catch {
      meta = {};
    }
  }
  return { meta, body, text };
}

function parseDoc(filePath, root) {
  const text = fs.readFileSync(filePath, 'utf8');
  return parseDocText(text, root);
}

function idPrefixFromFeatureId(featureId) {
  if (!featureId || typeof featureId !== 'string') return '';
  return featureId.toUpperCase().replace(/_/g, '-');
}

function findSection(body, heading) {
  const re = new RegExp(`^## ${heading.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\s*$`, 'im');
  const m = body.match(re);
  if (!m) return null;
  const start = m.index + m[0].length;
  const rest = body.slice(start);
  const next = rest.search(/^## /m);
  const section = next === -1 ? rest : rest.slice(0, next);
  const line =
    body.slice(0, start).split('\n').length;
  return { section, line, heading };
}

function parseMarkdownTable(section) {
  const lines = section.split('\n');
  let headerIdx = -1;
  for (let i = 0; i < lines.length; i += 1) {
    if (lines[i].trim().startsWith('|')) {
      headerIdx = i;
      break;
    }
  }
  if (headerIdx === -1) return null;
  const header = lines[headerIdx].trim();
  const rows = [];
  for (let i = headerIdx + 2; i < lines.length; i += 1) {
    const line = lines[i].trim();
    if (!line.startsWith('|')) break;
    const cells = line
      .split('|')
      .slice(1, -1)
      .map((c) => c.trim());
    rows.push({ cells, lineNum: i + 1 });
  }
  return { header, rows, headerLine: headerIdx + 1 };
}

function parseCanonicalDocFromText(text, root) {
  const { meta, body } = parseDocText(text, root);
  const prefix = idPrefixFromFeatureId(meta.feature_id);
  const reqSec = findSection(body, 'Requirements');
  const acSec = findSection(body, 'Acceptance criteria');
  const decSec = findSection(body, 'Decision log');
  const requirements = reqSec ? parseMarkdownTable(reqSec.section) : null;
  const acceptance = acSec ? parseMarkdownTable(acSec.section) : null;
  const decisions = decSec ? parseMarkdownTable(decSec.section) : null;
  return {
    meta,
    body,
    prefix,
    reqSec,
    acSec,
    decSec,
    requirements,
    acceptance,
    decisions,
  };
}

function parseCanonicalDoc(filePath, root) {
  const { text } = parseDoc(filePath, root);
  return parseCanonicalDocFromText(text, root);
}

function normalizeCoverageText(s) {
  return String(s || '')
    .replace(/[\u2018\u2019\u201A\u2032]/g, "'")
    .replace(/[\u201C\u201D\u201E\u2033]/g, '"')
    .replace(/\s+/g, ' ')
    .trim()
    .replace(/\.$/, '');
}

function isNormativeCoverage(cov, { allowLegacy = false } = {}) {
  const c = normalizeCoverageText(cov.replace(/^Coverage:\s*/i, ''));
  if (/^bdd:\s*.+\.(feature)(#.+|@\S+)$/i.test(c)) return true;
  if (/^test:\s*.+$/i.test(c)) return true;
  if (/^none\s*[—-]\s*#\d+$/i.test(c)) return true;
  if (/^TBD\s*[—-]\s*consolidate$/i.test(c)) return true;
  if (allowLegacy) {
    if (/\.feature`\s*[—-]\s*Scenario:/i.test(cov)) return true;
    if (/none\s*[—-]\s*issue\s*#\d+/i.test(c)) return true;
  }
  return false;
}

function decisionStatusOk(status) {
  const s = String(status || '').trim();
  if (DEC_STATUSES_LIVE.test(s)) return true;
  if (DEC_STATUSES_SUPER.test(s)) return true;
  return false;
}

function reqStatusOk(status) {
  return REQ_STATUSES.has(String(status || '').trim());
}

module.exports = {
  loadYaml,
  parseDoc,
  parseDocText,
  parseCanonicalDoc,
  parseCanonicalDocFromText,
  parseMarkdownTable,
  findSection,
  idPrefixFromFeatureId,
  normalizeCoverageText,
  isNormativeCoverage,
  decisionStatusOk,
  reqStatusOk,
};
