'use strict';

const { BOT_AUTHORS } = require('./constants');
const { finding } = require('./findings');
const { parseFrontmatter } = require('./yaml');
const {
  behaviourPathsInList,
  docsSectionPaths,
  isCanonicalFeatureDoc,
  isChangeDoc,
  domainFromDocPath,
} = require('./paths');
const { readFileAtRef, diffStatus } = require('./git');

function gatePrBody(ctx) {
  const findings = [];
  const { root, base, head, prBody, author, diffFiles } = ctx;

  if (author && BOT_AUTHORS.has(author)) {
    return findings;
  }

  const behaviour = behaviourPathsInList(diffFiles);
  if (behaviour.length === 0) {
    return findings;
  }

  const { hasSection, paths, na, naReason } = docsSectionPaths(prBody || '');
  if (!hasSection) {
    findings.push(
      finding('R-A1', 'BLOCK', 'Behaviour paths changed but PR body has no `## Docs` section.'),
    );
    return findings;
  }

  if (na) {
    if (naReason.length < 10) {
      findings.push(
        finding('R-A1', 'BLOCK', '`N/A —` reason must be at least 10 characters after the em dash.'),
      );
    }
    const highSignal = diffFiles.some(
      (f) =>
        f.includes('flutter_app/lib/l10n/') && f.endsWith('.arb') || f.startsWith('server/migrations/'),
    );
    if (highSignal) {
      findings.push(
        finding(
          'R-A5',
          'WARN',
          'Behaviour PR declares docs N/A but .arb or migrations changed.',
        ),
      );
    }
    const canonTouched = diffFiles.some((f) => isCanonicalFeatureDoc(f));
    if (canonTouched) {
      findings.push(
        finding(
          'R-A6',
          'WARN',
          'Canonical feature doc modified but `## Docs` says N/A.',
        ),
      );
    }
  } else {
    for (const docPath of paths) {
      if (!diffFiles.includes(docPath)) {
        findings.push(
          finding(
            'R-A3',
            'BLOCK',
            `Listed in ## Docs but not in PR diff: ${docPath}`,
            docPath,
          ),
        );
      }
    }
  }

  const statuses = diffStatus(root, base, head);
  for (const { status, file } of statuses) {
    if (status !== 'D' || !isChangeDoc(file)) {
      continue;
    }
    const prev = readFileAtRef(root, base, file);
    if (!prev) {
      continue;
    }
    let foldsInto = null;
    try {
      const { meta } = parseFrontmatterFromText(prev, root);
      foldsInto = meta?.folds_into || meta?.foldsInto;
    } catch {
      continue;
    }
    if (foldsInto) {
      const target = String(foldsInto).replace(/^\.\//, '');
      if (!diffFiles.includes(target)) {
        findings.push(
          finding(
            'R-A4',
            'BLOCK',
            `Deleted change doc ${file} without modifying folds_into target ${target}`,
            file,
          ),
        );
      }
    } else {
      const domain = domainFromDocPath(file);
      const featureModified = diffFiles.some(
        (f) =>
          domain &&
          f.startsWith(`docs/domains/${domain}/features/`) &&
          f.endsWith('.md'),
      );
      if (!featureModified) {
        findings.push(
          finding(
            'R-A4b',
            'BLOCK',
            `Deleted legacy change ${file} without modifying a feature doc in domain ${domain}`,
            file,
          ),
        );
      }
    }
  }

  return findings;
}

function parseFrontmatterFromText(text, root) {
  const fs = require('fs');
  const os = require('os');
  const path = require('path');
  const tmp = path.join(os.tmpdir(), `docs-gate-${Date.now()}.md`);
  fs.writeFileSync(tmp, text);
  try {
    return parseFrontmatter(tmp, root);
  } finally {
    fs.unlinkSync(tmp);
  }
}

module.exports = { gatePrBody };
