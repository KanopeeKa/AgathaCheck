'use strict';

const BEHAVIOUR_PREFIXES = [
  'flutter_app/lib/',
  'flutter_app/lib/l10n/',
  'server/routes/',
  'server/lib/',
  'server/migrations/',
  'server/bin/',
];

const BEHAVIOUR_EXCLUDE_PREFIXES = [
  'flutter_app/test/',
  'e2e/',
  'scripts/',
];

const GENERATED_SUFFIXES = ['.g.dart', '.mocks.dart', '.freezed.dart'];

const BOT_AUTHORS = new Set(['renovate[bot]', 'dependabot[bot]', 'github-actions[bot]']);

const VALID_REQ_STATUSES = new Set(['Live', 'In delivery', 'Planned', 'Retired']);
const VALID_CHANGE_STATUSES = new Set(['proposed', 'in-delivery', 'frozen', 'completed', 'superseded']);
const VALID_DECISION_STATUSES = /^Live$|^Superseded by [A-Z0-9][A-Z0-9-]*-D-\d{3}$/i;

const COVERAGE_RE =
  /^(bdd:\s*[^#]+\.(?:feature)(?:#[^|]+|@\S+)?|test:\s*.+#.+|none\s*—\s*#\d+)$/i;

const RULE_FIX = {
  'R-A1':
    'Add a `## Docs` section listing canonical doc paths updated, or `N/A — <reason ≥10 chars>`.',
  'R-A3': 'Every path under `## Docs` must appear in this PR diff.',
  'R-A4':
    'When deleting a `changes/` file with `folds_into`, modify the target canonical doc in the same PR.',
  'R-A4b':
    'Legacy change deletion without `folds_into` requires a modified `features/*.md` in the same domain.',
  'R-A5': 'High-signal paths (.arb, migrations) with `N/A` docs — confirm intent.',
  'R-A6': 'Canonical feature doc changed but `## Docs` says N/A — list the doc path.',
  'R-B1': 'New change docs cannot use `status: completed`; fold into canonical and delete instead.',
  'R-B3': '`in-delivery` requires `plan` (or `related_plan`) and valid `status_since` (YYYY-MM-DD).',
  'R-B4': 'Do not create new `*-decisions.md` under `changes/`; use canonical decision log.',
  'R-B5': 'Proposed change doc stale — review or move to in-delivery.',
  'R-C1': 'Add `## Decision log` section per feature-template.md.',
  'R-C3': 'Requirement/decision IDs must use prefix from `feature_id` (uppercase, `_` → `-`).',
  'R-C4': 'Decision `Status` must be `Live` or `Superseded by <ID>`.',
  'R-C6': 'Remove delivery noise (phase/shipped rows, `## Phasing`, amendment banners).',
  'R-C6-legacy': 'Baseline doc still has legacy delivery sections — schedule consolidate.',
  'R-D1': 'Do not remove requirement rows; mark `Retired` instead.',
  'R-D2': 'Decision rows are append-only; supersede instead of editing rationale.',
  'R-L1': 'Do not add paths to docs-legacy-baseline.json without team approval.',
  'R-L2': 'Remove stale paths from docs-legacy-baseline.json.',
  'R-L3': '(informational) Baseline doc exempt until touched.',
  'R-T2': 'New/changed AC rows need `bdd:`, `test:`, or `none — #issue`.',
  'R-T3': 'Coverage reference must match an existing BDD scenario or test name exactly.',
};

module.exports = {
  BEHAVIOUR_PREFIXES,
  BEHAVIOUR_EXCLUDE_PREFIXES,
  GENERATED_SUFFIXES,
  BOT_AUTHORS,
  VALID_REQ_STATUSES,
  VALID_CHANGE_STATUSES,
  VALID_DECISION_STATUSES,
  COVERAGE_RE,
  RULE_FIX,
};
