---
title: Phase Exit Checklists
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
tags: [agent-efficiency, policy]
---
# Phase exit checklists

Named profiles referenced by `exit_checklist` in plan snapshots. Agents must run **every applicable item** before calling babysit-plus merge step.

Canonical merge gates for PRs: [autonomous-pr-policy.md](./autonomous-pr-policy.md) §Merge gates.

---

## Profile index

| Profile | Use when |
|---------|----------|
| `default` | Any phase — always included |
| `flutter-screen-split` | Extracting widgets/screens under `flutter_app/lib/` |
| `single-backend-route` | Node route changes |
| `bdd-journey` | User journey / E2E behavior change |
| `governance` | Scripts, CI, allowlists, docs/agent-efficiency |

Profiles are **additive**: `exit_checklist: single-backend-route` means `default` + `single-backend-route` sections.

---

## default (always)

- [ ] Changes only in phase `allowed_paths` or mapped `allowed_exceptions`
- [ ] `node scripts/check_file_size.js` passes
- [ ] Hand-written files ≤ 500 lines (or allowlist ratchet only with `governance-allowlist` exception)
- [ ] `./scripts/pre-push-changed.sh` green
- [ ] `./scripts/pre-push.sh` green before merge attempt
- [ ] Babysit+ triage posted on PR
- [ ] All must-fix review items addressed in PR
- [ ] Deferred / ignored items tracked in GitHub issues (dedupe per autonomous-pr-policy)
- [ ] Commit messages use `phase(N/M):` prefix

---

## flutter-screen-split

Includes **default**.

- [ ] `flutter analyze --no-fatal-warnings --no-fatal-infos`
- [ ] `flutter test` for affected `test/features/<domain>/`
- [ ] Widget tests for newly extracted widgets
- [ ] Accessibility: semantic labels on new interactive controls (see `accessibility.mdc`)
- [ ] `file-split` exception files recorded in `exception_files` when adding new files

---

## single-backend-route

Includes **default**.

- [ ] Jest tests for route module (`server/test/<domain>/`)
- [ ] No raw exception text in prod 5xx responses
- [ ] Calendar dates as `YYYY-MM-DD` on the wire

---

## bdd-journey

Includes **default**.

- [ ] Gherkin scenario in `flutter_app/test/bdd/features/`
- [ ] Playwright spec with `/** @bdd <feature> */` — title exact match to Gherkin `Scenario:`
- [ ] `node e2e/scripts/check_bdd_coverage.js` (105/165 gate)
- [ ] `@smoke` tag if critical path

---

## governance

Includes **default**.

- [ ] `docs/architecture/index.md` or agent-efficiency doc updated if workflow changed
- [ ] No weakening of CI gates to pass
- [ ] `governance-allowlist` exception only when phase explicitly allows

---

## Profile composition examples

| `exit_checklist` value | Sections applied |
|------------------------|------------------|
| `default` | default |
| `flutter-screen-split` | default + flutter-screen-split |
| `single-backend-route` | default + single-backend-route |
| `bdd-journey` | default + bdd-journey |
| `governance` | default + governance |

For combined work (e.g. route + journey), list the **most specific** profile in the snapshot and add a `status_detail` note listing additional profiles to apply, or split into separate phases.

---

## Escalation (stop — do not merge)

- Security-sensitive auth/crypto changes
- Database migrations altering production data shape
- Breaking API contract without version bump
- CI workflow gate changes
- Product / legal / UX policy decisions
- Low-confidence review triage
- Drift detected
- Revoke or past `approved_until`
