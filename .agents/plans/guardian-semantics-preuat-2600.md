# Guardian semantics pre-UAT remedial (batch)

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `guardian-semantics-preuat-2600` |
| **title** | Batch E2E remedial for #670 Pet Care Today semantics drift |
| **author** | cloud-agent |
| **created** | 2026-08-21 |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Close the pre-UAT gate for `main` after #670 Pet Care Operations Desk semantics changes. Replace the serial one-shard-at-a-time remedial loop (#681–#687) with one batch PR, parallel **static** shard audits, sequential **local** tier-A shard runs on a single stack, merge, then `/babysit-uat` on that merge SHA.

**Supersedes** ad-hoc remedial strategy from the #679 chain (not `uat-pre-e2e-pipeline-5641` workflow infra).

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-08-21T21:15:00Z |
| **approved_until** | 2026-08-23T21:15:00Z |
| **control_issue** | (set in snapshot after bootstrap) |
| **autonomy** | `active` |

**Grant:** user chat 2026-08-21 — continue `/execute-plan` + `/babysit-uat`; override remedial strategy with parallel shard agents.

## Parallel shard agents — decision

| Approach | Verdict | Why |
|----------|---------|-----|
| Parallel **Playwright shard runs** on **one Cloud pod** | **Bad** | `babysit_uat_bootstrap_stack.sh` binds `:3000` + one Postgres; concurrent shards → signup 429, DB races, port fights |
| Parallel **static audit** Task agents (grep/locator review per shard group) | **Good** | Disjoint spec lists, no stack, fast |
| Parallel shard runs on **separate Cloud Agent pods** | **Optional** | True isolation; high cost; defer to GitHub pre-UAT (13 parallel jobs) post-merge |
| Sequential local tier-A shards (3, 6, 7, 12, 13) on orchestrator | **Required** | Pre-merge confidence without full 13-shard local replay |

## Tier map (semantics exposure from #670)

| Tier | Shards | Focus |
|------|--------|-------|
| A (direct / proven failures) | 3, 7, 12, 13 | login, vet phone, org edit, guardian.dashboard |
| B (shared page objects) | 6, 11 | pet.profiles, help.faq, sharing |
| C (indirect pet-list helpers) | 1, 8, 9 | adoption, org.pet.management, signup |
| D (low / skip local) | 2, 4, 5, 10 | health, weight, notifications, org.onboarding |

## Phases

### Phase 1 — Batch remedial + parallel audit + local tier-A + babysit-uat

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/preuat-fix-14c6c5b6-2600` |
| **spawn_allowed** | `true` |
| **exit_checklist** | `default` |

**allowed_paths:**

```
e2e/playwright/**
.agents/plans/guardian-semantics-preuat-2600.*
```

**Scope:**

1. Land vet detail merged-group phone fix (#687) + any audit findings on same branch
2. Spawn **3 parallel Task agents** — static audit only (no stack):
   - Agent A: shards 3, 12 specs — login, org edit headings
   - Agent B: shards 6, 11 specs — dashboardSectionGroup, Pet: patterns
   - Agent C: shards 1, 8, 9, 13 specs — petCard helpers, guardian.dashboard
3. Orchestrator: `./scripts/babysit_uat_bootstrap_stack.sh` then sequential `./scripts/babysit_uat_run_shard.sh` for **3, 6, 7, 12, 13**
4. `./scripts/pre-push-changed.sh`, push, babysit+ merge PR → `main`
5. `/babysit-uat`: `./scripts/babysit_uat_watch_preuat.sh <merge_sha>` until green

**Spawn phase ownership (audit only — no file edits by workers):**

| Agent | Shards | Owns (read-only) |
|-------|--------|------------------|
| audit-org-auth | 3, 12 | `auth.login.spec.ts`, `organisation.edit.spec.ts`, related pages |
| audit-pet-help | 6, 11 | `pet.profiles.spec.ts`, `help.faq.spec.ts`, `sharing.spec.ts` |
| audit-guardian-misc | 1, 8, 9, 13 | `guardian.dashboard.spec.ts`, adoption, signup, org.pet.management |

Orchestrator applies fixes on remedial branch; workers return drift reports only.

**Exit criteria:**

- [ ] PR #687 (or successor) merged to `main`
- [ ] Local tier-A shards 3, 6, 7, 12, 13 green before merge
- [ ] `pre-uat-e2e.yml` green for remedial merge SHA on `main`

## Runtime state

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "continue phase 1 on branch cursor/preuat-fix-14c6c5b6-2600"
artifact_ref:
  branch: cursor/preuat-fix-14c6c5b6-2600
  plan_path: .agents/plans/guardian-semantics-preuat-2600.md
  plan_commit: acea398c654acb8d45111fdeabefbe805c7ffd1a
  snapshot_path: .agents/plans/guardian-semantics-preuat-2600.snapshot.json
  snapshot_commit: acea398c654acb8d45111fdeabefbe805c7ffd1a
open_prs: ["https://github.com/KanopeeKa/AgathaCheck/pull/687"]
merge_commits: {}
debt_issue_refs: []
```
