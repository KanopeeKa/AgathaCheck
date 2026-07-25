# Phase R — Reconciliation

**Parent:** [`roadmap-delivery-plan.md`](roadmap-delivery-plan.md) · [`decisions-log.md`](decisions-log.md)

## Purpose

Close out conflicting or superseded prior work before any new implementation starts, so later
phases build on a clean, unambiguous baseline.

## In scope

- Mark `docs/design/navigation-v2.md` superseded (D2)
- Close the paused `org-mode-navigation-acf1` plan: branch `cursor/org-mode-nav-phase3-shell-acf1`,
  control issue #262, and its sibling orphaned branches
  (`plan-snapshot-uat-resume-4bed`, `sync-org-mode-plan-snapshot-acf1`) (D6)
- Tag affected BDD scenarios `@legacy` ahead of their Phase 1/2 rewrites (D1, D7, D18)
- Publish `docs/experience-program/` itself

## Out of scope / forbidden ownership

- No product behaviour changes
- No new screens, routes, or migrations
- Do not delete any `@legacy`-tagged scenario in this phase — only tag it

## Depends on

Nothing — this is the entry point.

## Domain objects and states

None (documentation-only phase).

## Business rules

1. `docs/design/navigation-v2.md` gets a status header identical in spirit to how
   `docs/experience-split-plan.md` was already marked superseded — link forward to
   `docs/experience-program/README.md`.
2. Before closing branch `cursor/org-mode-nav-phase3-shell-acf1`, diff it against `main` once more
   to confirm no unmerged change beyond the router-file extraction has appeared since the last
   check in this program's planning session (2026-07-25) — if new commits exist, re-evaluate D6
   rather than assuming it still holds.
3. Control issue #262 gets a closing comment explaining the supersession (link to D6 and this
   phase doc), then is closed. Do not silently delete the issue.
4. `@legacy` tagging follows the exact G0 §14.2 pattern already used elsewhere in this repo — add
   the tag to the `Feature:` or individual `Scenario:` lines, do not restructure the file yet.

## Screens and navigation

None.

## Notifications

None.

## Permissions

None.

## Audit events

None.

## Phases with exit criteria

Single phase, sprints R.1–R.4 (see `roadmap-delivery-plan.md`).

**Exit criteria:**

- `docs/experience-program/` merged to `main`
- `docs/design/navigation-v2.md` header updated
- Branch `cursor/org-mode-nav-phase3-shell-acf1` and its siblings deleted; issue #262 closed
- `@legacy` tags present on `experience_navigation.feature`, `notifications.feature`,
  `organisation_pet_timeline.feature`
- `node e2e/scripts/check_bdd_coverage.js --report-only` shows no scenario count regression
  (tagging alone doesn't remove scenarios)

## Migration / compatibility

N/A.

## Legal/document dependencies

None.

## Open questions

None outstanding — this phase is a housekeeping close-out with decisions already locked (D1–D6).

## Canonical BDD scenarios

None — this phase produces no new behaviour to specify.
