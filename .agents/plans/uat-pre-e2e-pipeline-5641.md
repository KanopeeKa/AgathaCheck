# UAT pre-E2E pipeline refactor

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `uat-pre-e2e-pipeline-5641` |
| **title** | Pre-UAT E2E gate + light deploy |
| **author** | cloud-agent |
| **created** | 2026-07-26 |
| **base_branch** | `cursor/uat-pre-e2e-pipeline-integration-5641` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Move full localhost Playwright E2E before UAT tagging (pre-UAT gate with merge bundling via workflow concurrency), make UAT deploy light (HTTP smoke only), add advisory nightly live UAT E2E, and remove deploy/E2E cadence workflows.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-07-26T23:55:00Z |
| **approved_until** | 2026-07-28T23:55:00Z |
| **control_issue** | TBD |
| **autonomy** | `active` |

**Grant:** user chat `/execute-plan` — "you're good to go"

## Phases

### Phase 1 — Pre-UAT E2E + promote trigger

**id:** `1` · **branch:** `cursor/pre-uat-e2e-workflows-5641`

- `pre-uat-e2e.yml` on push to main (single-flight queue, test latest HEAD)
- `promote-uat.yml` triggered by Pre-UAT E2E success (not push to main)
- Remove deploy cadence from promote-uat
- Delete `uat-promote-catchup.yml`

### Phase 2 — Light deploy-uat + gate script

**id:** `2` · **branch:** `cursor/light-deploy-uat-5641`

- Remove `uat-e2e-smoke`, `uat-e2e-full`, cadence jobs from deploy-uat
- Simplify `assert-uat-gates.sh`
- Add `uat-live-e2e.yml` (nightly advisory)
- Delete cadence scripts; update coordinator classifiers

### Phase 3 — Docs, rules, skills sync

**id:** `3` · **branch:** `cursor/uat-pipeline-docs-5641`

- `docs/e2e/uat-deploy-tiers.md`, ci-cd-gates, promotion-contract, memory, rules, skills

## Runtime state

```yaml
autonomy: active
current_phase: "1"
last_completed_phase: null
```
