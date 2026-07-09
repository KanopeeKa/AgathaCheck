'use strict';

const { detectRiskyScope, parseSections } = require('./triage-lib');

const FORBIDDEN_PATH_PREFIXES = [
  '.github/workflows/',
  'db/migrations/',
  'server/config/security.js',
  'infra/',
];

const FORBIDDEN_PATH_PATTERNS = [
  /^\.github\/workflows\//,
  /^db\/migrations\//,
  /^server\/config\/security\.js$/,
  /^infra\//,
  /\/secrets?\//i,
  /\/auth\//i,
  /\/billing\//i,
];

const DEFAULT_ALLOWED_PATH_PREFIXES = [
  'flutter_app/',
  'server/',
  'e2e/',
  'docs/',
  'scripts/',
  '.github/ISSUE_TEMPLATE/',
  '.github/scripts/',
];

const FORBIDDEN_ACTIONS = [
  'push directly to main',
  'bypass pull requests',
  'modify GitHub Actions workflows',
  'add or read repository secrets',
  'run production deployments',
  'apply database migrations',
  'modify authentication, billing, or permissions code',
];

function issueHasBlockingLabels(labels) {
  const normalized = labels.map((l) => l.toLowerCase());
  return (
    normalized.includes('busy') ||
    normalized.includes('manual-only') ||
    normalized.includes('question') ||
    normalized.includes('blocked')
  );
}

function preflightIssue(issue) {
  const labels = (issue.labels?.nodes || issue.labels || []).map((l) =>
    typeof l === 'string' ? l : l.name,
  );
  const title = issue.title || '';
  const body = issue.body || '';

  if (!labels.map((l) => l.toLowerCase()).includes('agent-approved')) {
    return { ok: false, reason: 'missing agent-approved label' };
  }

  if (issueHasBlockingLabels(labels)) {
    return { ok: false, reason: 'issue has blocking label (busy, manual-only, question, blocked)' };
  }

  const sections = parseSections(body);
  const risks = detectRiskyScope(title, body, sections);
  if (risks.length > 0) {
    return { ok: false, reason: `risky scope detected: ${risks.join(', ')}` };
  }

  return { ok: true };
}

function isForbiddenPath(filePath) {
  return FORBIDDEN_PATH_PATTERNS.some((pattern) => pattern.test(filePath));
}

function findForbiddenPaths(changedFiles) {
  return changedFiles.filter((file) => isForbiddenPath(file));
}

function buildSafetyConstraints() {
  return {
    allowedPaths: DEFAULT_ALLOWED_PATH_PREFIXES,
    forbiddenPaths: FORBIDDEN_PATH_PREFIXES,
    forbiddenActions: FORBIDDEN_ACTIONS,
  };
}

module.exports = {
  FORBIDDEN_PATH_PREFIXES,
  FORBIDDEN_PATH_PATTERNS,
  DEFAULT_ALLOWED_PATH_PREFIXES,
  issueHasBlockingLabels,
  preflightIssue,
  isForbiddenPath,
  findForbiddenPaths,
  buildSafetyConstraints,
};
