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
};
