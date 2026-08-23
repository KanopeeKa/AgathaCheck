#!/usr/bin/env node
'use strict';

/**
 * Validate documentation placement per docs/domains/documentation/standards.md.
 *
 * Usage:
 *   node scripts/check_doc_placement.js            # placement rules (default)
 *   node scripts/check_doc_placement.js --hex-colors
 *   node scripts/check_doc_placement.js --feature-manifest
 */
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const DOCS = path.join(ROOT, 'docs');

const ROOT_ALLOWLIST = new Set(['README.md', 'CHANGELOG.md', 'refactoring-log.md']);

const HEX_ALLOWLIST = new Set([
  path.join(DOCS, 'design', 'tokens.md'),
  path.join(DOCS, 'design', 'system.md'),
]);

const PLAN_FILENAME_PATTERNS = [
  /delivery-plan\.md$/i,
  /execution-plan\.md$/i,
  /-delivery-plan\.md$/i,
  /-execution-plan\.md$/i,
];

// 6-digit hex colours (#RRGGBB). Shorter #RGB must appear in backticks.
const HEX_COLOR_RE = /#[0-9A-Fa-f]{6}\b|`#[0-9A-Fa-f]{3}`/g;

let errors = 0;

function rel(filePath) {
  return path.relative(ROOT, filePath);
}

function fail(message) {
  console.error(message);
  errors += 1;
}

function warn(message) {
  console.error(`WARN: ${message}`);
}

function loadYaml() {
  try {
    return require('js-yaml');
  } catch {
    try {
      return require(path.join(ROOT, 'server/node_modules/js-yaml'));
    } catch {
      console.error(
        'check_doc_placement: js-yaml is required. Install backend deps: cd server && npm ci',
      );
      process.exit(1);
    }
  }
}

function walkMarkdown(dir, visitor) {
  if (!fs.existsSync(dir)) {
    return;
  }
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      walkMarkdown(fullPath, visitor);
    } else if (entry.isFile() && entry.name.endsWith('.md')) {
      visitor(fullPath);
    }
  }
}

function parseFrontmatter(filePath) {
  const text = fs.readFileSync(filePath, 'utf8');
  const match = text.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  if (!match) {
    return null;
  }
  const yaml = loadYaml();
  try {
    return yaml.load(match[1]);
  } catch (error) {
    throw new Error(`invalid YAML frontmatter: ${error.message}`);
  }
}

function checkRootDocs() {
  if (!fs.existsSync(DOCS)) {
    return;
  }
  for (const entry of fs.readdirSync(DOCS, { withFileTypes: true })) {
    if (!entry.isFile() || !entry.name.endsWith('.md')) {
      continue;
    }
    if (!ROOT_ALLOWLIST.has(entry.name)) {
      fail(
        `Misplaced root doc: docs/${entry.name} (allowed: ${[...ROOT_ALLOWLIST].join(', ')})`,
      );
    }
  }
}

function checkLessonsUnderDomains() {
  const domainsDir = path.join(DOCS, 'domains');
  walkMarkdown(domainsDir, (filePath) => {
    if (path.basename(filePath) === 'lessons.md') {
      fail(
        `Forbidden lessons.md under domains: ${rel(filePath)} (extract durable rules into features/, then delete)`,
      );
    }
  });
}

function checkPlansInFeatures() {
  const domainsDir = path.join(DOCS, 'domains');
  walkMarkdown(domainsDir, (filePath) => {
    if (!filePath.includes(`${path.sep}features${path.sep}`)) {
      return;
    }

    const baseName = path.basename(filePath);
    for (const pattern of PLAN_FILENAME_PATTERNS) {
      if (pattern.test(baseName)) {
        fail(
          `Delivery/plan doc in features/: ${rel(filePath)} (belongs under domains/<d>/changes/ or docs/design/plans/)`,
        );
        return;
      }
    }

    let frontmatter;
    try {
      frontmatter = parseFrontmatter(filePath);
    } catch (error) {
      fail(`${rel(filePath)}: ${error.message}`);
      return;
    }

    const title = String(frontmatter?.title || '').toLowerCase();
    if (title.includes('delivery plan') || title.includes('execution plan')) {
      warn(
        `Feature doc title looks like a delivery plan: ${rel(filePath)} (title: ${frontmatter.title})`,
      );
    }
  });
}

function checkPlacement() {
  console.log('check_doc_placement: validating documentation placement...');
  checkRootDocs();
  checkLessonsUnderDomains();
  checkPlansInFeatures();
}

function lineNumberForMatch(text, index) {
  return text.slice(0, index).split('\n').length;
}

function checkHexColors() {
  console.log('check_doc_placement: scanning docs for hex colour codes...');
  walkMarkdown(DOCS, (filePath) => {
    if (HEX_ALLOWLIST.has(filePath)) {
      return;
    }

    const text = fs.readFileSync(filePath, 'utf8');
    const matches = [...text.matchAll(HEX_COLOR_RE)];
    for (const match of matches) {
      const line = lineNumberForMatch(text, match.index);
      fail(
        `Hex colour in ${rel(filePath)}:${line} (${match[0]}) — use token names; hex only in docs/design/tokens.md and docs/design/system.md`,
      );
    }
  });
}

function domainFromFeaturePath(filePath) {
  const parts = rel(filePath).split(path.sep);
  const domainsIndex = parts.indexOf('domains');
  if (domainsIndex === -1 || domainsIndex + 1 >= parts.length) {
    return null;
  }
  return parts[domainsIndex + 1];
}

function checkFeatureManifest() {
  console.log('check_doc_placement: validating feature doc frontmatter manifests...');
  const featuresRoot = path.join(DOCS, 'domains');
  walkMarkdown(featuresRoot, (filePath) => {
    if (!filePath.includes(`${path.sep}features${path.sep}`)) {
      return;
    }

    let frontmatter;
    try {
      frontmatter = parseFrontmatter(filePath);
    } catch (error) {
      fail(`${rel(filePath)}: ${error.message}`);
      return;
    }

    if (!frontmatter) {
      fail(`${rel(filePath)}: missing YAML frontmatter`);
      return;
    }

    if (!frontmatter.title) {
      fail(`${rel(filePath)}: frontmatter missing required field "title"`);
    }

    const hasFeatureId =
      typeof frontmatter.feature_id === 'string' && frontmatter.feature_id.trim() !== '';
    const hasDomain =
      typeof frontmatter.domain === 'string' && frontmatter.domain.trim() !== '';

    if (!hasFeatureId && !hasDomain) {
      fail(
        `${rel(filePath)}: frontmatter needs "feature_id" or "domain" (see docs/domains/documentation/standards.md)`,
      );
      return;
    }

    if (hasDomain) {
      const expectedDomain = domainFromFeaturePath(filePath);
      if (expectedDomain && frontmatter.domain !== expectedDomain) {
        fail(
          `${rel(filePath)}: domain "${frontmatter.domain}" does not match path domain "${expectedDomain}"`,
        );
      }
    }
  });
}

function main() {
  const mode = process.argv.find((arg) => arg.startsWith('--')) || '--placement';
  errors = 0;

  switch (mode) {
    case '--placement':
      checkPlacement();
      break;
    case '--hex-colors':
      checkHexColors();
      break;
    case '--feature-manifest':
      checkFeatureManifest();
      break;
    default:
      console.error(`Unknown mode: ${mode}`);
      process.exit(1);
  }

  if (errors > 0) {
    console.error(`check_doc_placement: ${errors} error(s)`);
    process.exit(1);
  }

  console.log('check_doc_placement: OK');
}

main();
