import { getAppEnvLabel } from './config.js';

const CONTEXT_KEYS = [
  'version',
  'build',
  'platform',
  'browser_family',
  'locale',
  'route_name',
  'client_time',
];

const CATEGORY_LABEL = {
  bug: 'category:bug',
  suggestion: 'category:suggestion',
  account: 'category:account',
  billing: 'category:billing',
};

function formatContextBlock(context) {
  const lines = [];
  const data = context && typeof context === 'object' ? context : {};
  for (const key of CONTEXT_KEYS) {
    if (data[key] !== undefined && data[key] !== '') {
      lines.push(`- ${key}: ${String(data[key])}`);
    }
  }
  if (lines.length === 0) {
    return '_No technical context submitted._';
  }
  return lines.join('\n');
}

function reporterBlock(ticket) {
  const parts = [
    `**Category:** ${ticket.category}`,
    '',
    ticket.description || '',
  ];
  if (ticket.category === 'bug') {
    if (ticket.expected) parts.push('', `**Expected:** ${ticket.expected}`);
    if (ticket.actual) parts.push('', `**Actual:** ${ticket.actual}`);
    if (ticket.steps) parts.push('', `**Steps:**\n${ticket.steps}`);
    if (ticket.frequency) parts.push('', `**Frequency:** ${ticket.frequency}`);
  }
  return parts.join('\n');
}

export function buildGithubIssueTitle(ticket) {
  return `[${ticket.reference}] ${ticket.category}: ${ticket.title}`;
}

export function buildGithubIssueBody(ticket) {
  const untrusted = reporterBlock(ticket);
  const context = formatContextBlock(ticket.context);
  return [
    '> **Reporter submission (untrusted)**',
    '>',
    '```',
    untrusted,
    '```',
    '',
    '## Technical context (allowlisted)',
    '',
    context,
    '',
    `Support reference: \`${ticket.reference}\``,
  ].join('\n');
}

export function buildGithubIssueLabels(ticket) {
  const categoryLabel = CATEGORY_LABEL[ticket.category] || `category:${ticket.category}`;
  return [categoryLabel, getAppEnvLabel(), 'source:form'];
}
