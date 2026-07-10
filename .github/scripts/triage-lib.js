'use strict';

/** Minimum trimmed length for a required section to count as present. */
const MIN_SECTION_LENGTH = 15;

/** Minimum trimmed title length (after common prefixes). */
const MIN_TITLE_LENGTH = 10;

/** Minimum total body length for non-vague issues. */
const MIN_BODY_LENGTH = 80;

const PLACEHOLDER_PATTERNS = [
  /^tbd$/i,
  /^fix later$/i,
  /^todo$/i,
  /^n\/?a$/i,
  /^asdf+$/i,
  /^xxx+$/i,
  /^\.+$/,
  /^-+$/,
  /^lorem ipsum/i,
];

const INJECTION_PATTERNS = [
  /ignore (all )?(previous|prior) instructions/i,
  /you are now/i,
  /system prompt/i,
  /<\s*script/i,
  /javascript:/i,
];

const RISK_PATTERNS = [
  { pattern: /\bauth(entication|orize|orization|orised|orized)?\b/i, reason: 'authentication' },
  { pattern: /\bbilling\b/i, reason: 'billing' },
  { pattern: /\bpayment(s)?\b/i, reason: 'payments' },
  { pattern: /\bsecret(s)?\b/i, reason: 'secrets' },
  { pattern: /\bcredential(s)?\b/i, reason: 'credentials' },
  { pattern: /\bapi[_ -]?key(s)?\b/i, reason: 'API keys' },
  { pattern: /\binfra(structure)?\b/i, reason: 'infrastructure' },
  { pattern: /\bterraform\b/i, reason: 'Terraform' },
  { pattern: /\bpulumi\b/i, reason: 'Pulumi' },
  { pattern: /\bdatabase migration(s)?\b/i, reason: 'database migrations' },
  { pattern: /\b(db )?migration(s)?\b/i, reason: 'migrations' },
  { pattern: /\.github\/workflows\b/i, reason: 'GitHub workflow files' },
  { pattern: /\bgithub actions?\b/i, reason: 'GitHub Actions' },
  { pattern: /\bci\/cd\b/i, reason: 'CI/CD' },
  { pattern: /\bpermissions?\b/i, reason: 'permissions' },
  { pattern: /\baccess control\b/i, reason: 'access control' },
  { pattern: /\broles?\b/i, reason: 'roles' },
];

const BUG_SECTIONS = [
  'current behavior',
  'expected behavior',
  'steps to reproduce',
  'environment',
];

const FEATURE_SECTIONS = [
  'problem to solve',
  'proposed solution',
  'acceptance criteria',
];

const TASK_SECTIONS = [
  'objective',
  'scope',
  'definition of done',
];

/**
 * Parse GitHub issue form markdown sections keyed by lowercased heading.
 * @param {string | null | undefined} body
 * @returns {Record<string, string>}
 */
function parseSections(body) {
  const sections = {};
  if (!body) return sections;

  const parts = body.split(/^### /m);
  for (const part of parts.slice(1)) {
    const newline = part.indexOf('\n');
    if (newline === -1) continue;
    const heading = part.slice(0, newline).trim().toLowerCase();
    const content = part.slice(newline + 1).trim();
    sections[heading] = content;
  }
  return sections;
}

/**
 * @param {string | null | undefined} value
 * @param {number} [minLength]
 */
function isMeaningfulText(value, minLength = MIN_SECTION_LENGTH) {
  if (!value) return false;
  const trimmed = value.replace(/\s+/g, ' ').trim();
  if (trimmed.length < minLength) return false;
  if (PLACEHOLDER_PATTERNS.some((re) => re.test(trimmed))) return false;
  return true;
}

/**
 * @param {string} title
 */
function isValidTitle(title) {
  return isMeaningfulText(normalizeTitle(title), MIN_TITLE_LENGTH);
}

/**
 * @param {string} title
 */
function normalizeTitle(title) {
  return title.replace(/^\[(BUG|FEATURE|TASK)\]\s*/i, '').trim();
}

/**
 * @param {string} text
 */
function detectInjection(text) {
  return INJECTION_PATTERNS.find((re) => re.test(text));
}

/**
 * @param {string} title
 * @param {string} body
 * @param {Record<string, string>} sections
 */
function detectRiskyScope(title, body, sections) {
  const reasons = [];
  const combined = `${title}\n${body}`;

  for (const { pattern, reason } of RISK_PATTERNS) {
    if (pattern.test(combined)) {
      reasons.push(reason);
    }
  }

  const sensitive = sections['security or sensitive area'];
  if (sensitive && isSensitiveAreaDeclared(sensitive)) {
    reasons.push('declared sensitive/security area');
  }

  return [...new Set(reasons)];
}

/**
 * @param {string} content
 */
function isSensitiveAreaDeclared(content) {
  const normalized = content.trim().toLowerCase();
  if (!normalized || normalized === 'no' || normalized.startsWith('no ')) {
    return false;
  }
  return /\byes\b/i.test(content);
}

/**
 * @param {string[]} labels lowercased label names
 */
function detectIssueType(labels) {
  if (labels.includes('bug')) return 'bug';
  if (labels.includes('feature')) return 'feature';
  if (labels.includes('task')) return 'task';
  return 'unknown';
}

/**
 * @param {Record<string, string>} sections
 * @param {string[]} requiredHeadings lowercased section headings
 */
function findMissingSections(sections, requiredHeadings) {
  const missing = [];
  for (const heading of requiredHeadings) {
    const content = sections[heading];
    if (!isMeaningfulText(content)) {
      missing.push(heading);
    }
  }
  return missing;
}

/**
 * Deterministic triage evaluation.
 * @param {{ title: string, body: string, labels: string[] }} issue
 * @returns {{
 *   decision: 'pass' | 'question' | 'manual-only',
 *   missing: string[],
 *   risks: string[],
 *   reasons: string[],
 * }}
 */
function evaluateIssue(issue) {
  const title = issue.title || '';
  const body = issue.body || '';
  const labels = (issue.labels || []).map((l) => l.toLowerCase());
  const sections = parseSections(body);
  const missing = [];
  const reasons = [];

  const normalizedTitle = normalizeTitle(title);
  if (!isValidTitle(title)) {
    missing.push('summary / title');
  }

  if (body.trim().length < MIN_BODY_LENGTH) {
    reasons.push('issue body is too short to be actionable');
  }

  const injection = detectInjection(`${title}\n${body}`);
  if (injection) {
    reasons.push('issue text matches disallowed placeholder or injection patterns');
  }

  const issueType = detectIssueType(labels);

  if (issueType === 'bug') {
    missing.push(...findMissingSections(sections, BUG_SECTIONS));
    if (!isMeaningfulText(sections['expected behavior'])) {
      if (!missing.includes('expected behavior')) missing.push('expected behavior');
    }
  } else if (issueType === 'feature') {
    missing.push(...findMissingSections(sections, FEATURE_SECTIONS));
    if (!isMeaningfulText(sections.summary) && !isMeaningfulText(normalizedTitle)) {
      if (!missing.includes('summary')) missing.push('summary');
    }
  } else if (issueType === 'task') {
    missing.push(...findMissingSections(sections, TASK_SECTIONS));
    if (!isMeaningfulText(sections.summary) && !isMeaningfulText(normalizedTitle)) {
      if (!missing.includes('summary')) missing.push('summary');
    }
  } else {
    reasons.push('missing issue type label (`bug`, `feature`, or `task`)');
    if (!isMeaningfulText(body)) {
      missing.push('objective / problem statement');
      missing.push('acceptance criteria or expected outcome');
    }
  }

  const uniqueMissing = [...new Set(missing)];
  const risks = detectRiskyScope(title, body, sections);

  if (risks.length > 0) {
    return {
      decision: 'manual-only',
      missing: uniqueMissing,
      risks,
      reasons,
    };
  }

  if (uniqueMissing.length > 0 || reasons.length > 0) {
    return {
      decision: 'question',
      missing: uniqueMissing,
      risks,
      reasons,
    };
  }

  return {
    decision: 'pass',
    missing: [],
    risks: [],
    reasons: [],
  };
}

/**
 * @param {{ decision: string, missing: string[], risks: string[], reasons: string[] }} result
 */
function buildComment(result) {
  const marker = '<!-- triage-human-reviewed -->';

  if (result.decision === 'pass') {
    return `${marker}
## Triage result: approved

This issue passed deterministic checks and is marked **Ready** for implementation.

- Label \`agent-approved\` was added.
- Project status was set to **Ready**.

The issue is eligible for Cursor handoff when your team is ready.`;
  }

  if (result.decision === 'manual-only') {
    const riskList = result.risks.map((r) => `- ${r}`).join('\n');
    const missingBlock =
      result.missing.length > 0
        ? `\n\n**Also missing or weak fields:**\n${result.missing.map((m) => `- ${m}`).join('\n')}`
        : '';

    return `${marker}
## Triage result: manual only

This issue touches sensitive areas and must be handled manually. It should **not** be sent to Cursor.

**Detected sensitive scope:**
${riskList}
${missingBlock}

Please plan and implement this work with human review. When updated, you may re-add the \`human-reviewed\` label to re-run checks.`;
  }

  const missingList = result.missing.map((m) => `- ${m}`).join('\n');
  const reasonList =
    result.reasons.length > 0
      ? `\n\n**Other problems:**\n${result.reasons.map((r) => `- ${r}`).join('\n')}`
      : '';

  return `${marker}
## Triage result: more information needed

The deterministic checker could not approve this issue yet. Please update the issue body with the missing fields, then re-add \`human-reviewed\` when ready (triage will clear \`question\` automatically when checks pass).

**Missing or insufficient fields:**
${missingList}
${reasonList}

Project status was moved to **Backlog** until the issue is updated.`;
}

module.exports = {
  MIN_SECTION_LENGTH,
  MIN_TITLE_LENGTH,
  MIN_BODY_LENGTH,
  parseSections,
  isMeaningfulText,
  isValidTitle,
  evaluateIssue,
  buildComment,
  detectRiskyScope,
};
