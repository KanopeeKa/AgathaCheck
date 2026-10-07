'use strict';

const SEVERITY = {
  BLOCK: 'BLOCK',
  WARN: 'WARN',
  REPORT: 'REPORT',
};

const REQ_HEADER = '| ID | Rule | Status |';
const AC_HEADER = '| Given / When / Then | Requirement | Coverage |';
const DEC_HEADER = '| ID | Decision | Rationale | Status | Date | PR |';

const REQ_STATUSES = new Set(['Live', 'In delivery', 'Planned', 'Retired']);
const DEC_STATUSES_LIVE = /^Live$/i;
const DEC_STATUSES_SUPER = /^Superseded by .+$/i;

const NA_PLACEHOLDERS = new Set(['todo', 'tbd', '-', '…', '...', 'n/a', 'na']);

const EXEMPT_AUTHORS = new Set(['dependabot[bot]', 'renovate[bot]', 'github-actions[bot]']);

// Fixed prefixes for bare legacy decision IDs (D1, D2, …) when their domain is
// consolidated. One prefix per legacy domain so IDs never collide. Keep in sync
// with the table in docs/domains/documentation/standards.md.
const LEGACY_DECISION_PREFIXES = ['NAV', 'NOTIF', 'PETPROF', 'SHELTER', 'XDOM', 'PEOPLE'];

/** Valid decision ID: `<PREFIX>-D-###`, a kept `D-XXX-###` legacy ID, or `<LEGACY>-D<n>`. */
function isValidDecisionId(id, prefix) {
  if (prefix && new RegExp(`^${prefix}-D-\\d{3}$`).test(id)) return true;
  if (/^D-[A-Z]+-\d{3}$/.test(id)) return true;
  return new RegExp(`^(${LEGACY_DECISION_PREFIXES.join('|')})-D\\d+$`).test(id);
}

const POLICY_DOC_GLOBS = [
  /^docs\/domains\/documentation\//,
  /^docs\/agent-efficiency\//,
];

module.exports = {
  SEVERITY,
  REQ_HEADER,
  AC_HEADER,
  DEC_HEADER,
  REQ_STATUSES,
  DEC_STATUSES_LIVE,
  DEC_STATUSES_SUPER,
  NA_PLACEHOLDERS,
  EXEMPT_AUTHORS,
  POLICY_DOC_GLOBS,
  LEGACY_DECISION_PREFIXES,
  isValidDecisionId,
};
