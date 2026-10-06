'use strict';

const { SEVERITY, NA_PLACEHOLDERS, EXEMPT_AUTHORS } = require('./constants');
const { rel, isBehaviourPath, domainFromFeaturePath } = require('./paths');
const { parseDoc } = require('./parse');
const { fileAtRef, workingTreeFile, touchedInDiff } = require('./diff');

function parseDocsSection(body) {
  const idx = body.search(/^## Docs\b/im);
  if (idx === -1) return { hasSection: false, content: '' };
  const after = body.slice(idx).replace(/^## Docs\b[^\n]*\n?/im, '');
  const next = after.search(/^## /m);
  const content = next === -1 ? after : after.slice(0, next);
  return { hasSection: true, content };
}

function extractFeaturePaths(docsContent) {
  const paths = [];
  const re = /docs\/domains\/[^\s,)]+?\/features\/[^\s,)]+?\.md/g;
  let match;
  while ((match = re.exec(docsContent)) !== null) {
    paths.push(match[0]);
  }
  return [...new Set(paths)];
}

function isNaDocs(content) {
  const m = content.match(/N\/A\s*[—-]\s*(.+)/i);
  if (!m) return { isNa: false };
  const reason = m[1].trim();
  return { isNa: true, reason };
}

function runGatePrBody(ctx) {
  const findings = [];
  const { root, diff, bodyText, author, labels } = ctx;
  if (EXEMPT_AUTHORS.has(author || '')) return findings;
  if ((labels || []).includes('docs-gate-exempt')) return findings;

  let touchesBehaviour = false;
  let touchesArbOrMigration = false;
  for (const p of [...diff.added, ...diff.modified]) {
    if (isBehaviourPath(p)) touchesBehaviour = true;
    if (p.startsWith('flutter_app/lib/l10n/') && p.endsWith('.arb')) touchesArbOrMigration = true;
    if (p.startsWith('server/migrations/')) touchesArbOrMigration = true;
  }

  const { hasSection, content } = parseDocsSection(bodyText || '');
  const listedFeatures = extractFeaturePaths(content);
  const na = isNaDocs(content);

  if (touchesBehaviour && !hasSection) {
    findings.push({
      ruleId: 'R-A1',
      severity: SEVERITY.BLOCK,
      message:
        'Add `## Docs`: canonical doc path(s) updated, or `N/A — <reason>`. See `/canonical-docs` Mode A.',
    });
  }

  if (hasSection && na.isNa) {
    const reasonNorm = na.reason.toLowerCase().trim();
    if (na.reason.length < 10 || NA_PLACEHOLDERS.has(reasonNorm)) {
      findings.push({
        ruleId: 'R-A2',
        severity: SEVERITY.BLOCK,
        message: 'Give a real reason, e.g. `N/A — refactor, no contract change`.',
      });
    }
  }

  for (const fp of listedFeatures) {
    if (!touchedInDiff(diff, fp)) {
      findings.push({
        ruleId: 'R-A3',
        severity: SEVERITY.BLOCK,
        file: fp,
        message: `\`${fp}\` is listed under \`## Docs\` but not changed in this PR.`,
      });
    }
  }

  for (const p of diff.deleted) {
    if (!p.includes('/changes/') || !p.endsWith('.md')) continue;
    const baseText = fileAtRef(root, ctx.baseRef, p);
    if (!baseText) continue;
    const { meta } = parseDocText(baseText, root);
    const folds = meta.folds_into;
    if (folds) {
      const target = folds.replace(/^\//, '');
      if (!touchedInDiff(diff, target)) {
        findings.push({
          ruleId: 'R-A4',
          severity: SEVERITY.BLOCK,
          file: p,
          message: `Fold \`${p}\` into \`${target}\` in the same PR before deleting it.`,
        });
      }
    } else {
      const domain = domainFromFeaturePath(p);
      let domainFeatureTouched = false;
      if (domain) {
        for (const ch of [...diff.added, ...diff.modified]) {
          if (ch.startsWith(`docs/domains/${domain}/features/`) && ch.endsWith('.md')) {
            domainFeatureTouched = true;
            break;
          }
        }
      }
      if (!domainFeatureTouched) {
        findings.push({
          ruleId: 'R-A4b',
          severity: SEVERITY.BLOCK,
          file: p,
          message: `Deleting \`${p}\` requires updating its canonical doc in the same domain in this PR.`,
        });
      }
    }
  }

  if (hasSection && na.isNa && touchesArbOrMigration) {
    findings.push({
      ruleId: 'R-A5',
      severity: SEVERITY.WARN,
      message: 'Copy and migration changes are usually behaviour — double-check the N/A.',
    });
  }

  if (touchesBehaviour && hasSection && na.isNa) {
    for (const ch of [...diff.added, ...diff.modified]) {
      if (ch.includes('/features/') && ch.endsWith('.md')) {
        findings.push({
          ruleId: 'R-A6',
          severity: SEVERITY.WARN,
          message: 'You changed a canonical doc — list it under `## Docs` instead of N/A.',
        });
        break;
      }
    }
  }

  return findings;
}

function parseDocText(text, root) {
  const { loadYaml } = require('./parse');
  if (!text.startsWith('---\n')) return { meta: {} };
  const end = text.indexOf('\n---\n', 4);
  if (end === -1) return { meta: {} };
  const yaml = loadYaml(root);
  try {
    return { meta: yaml.load(text.slice(4, end)) || {} };
  } catch {
    return { meta: {} };
  }
}

module.exports = { runGatePrBody, parseDocsSection, extractFeaturePaths, isBehaviourPath };
