# Execute-plan: docs domain-first reorganization

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `docs-domain-reorg-63ad` |
| **title** | Reorganize docs into domain-first `docs/domains/` tree |
| **author** | Cloud agent |
| **created** | 2026-08-22 |
| **base_branch** | `cursor/docs-domain-reorg-integration-63ad` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Migrate AgathaTrack documentation from document-type-first layout into a **domain-first** `docs/domains/<domain>/` structure per the reorg prompt. Preserve git history via `git mv`, link out to `.agents/plans/` and `.agents/memory/` (never move those), use AgathaTrack naming in prose, and seed substantive stubs for `weight_tracking` and `vet`.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-08-22T15:52:00Z |
| **approved_until** | 2026-08-24T15:52:00Z |
| **control_issue** | (set at bootstrap) |
| **autonomy** | `active` |

**Grant:** Standing grant from user chat 2026-08-22 — `/execute-plan` docs reorg prompt + follow-ups (AgathaTrack naming, weight/vet stubs).

---

## Phases

### Phase 1 — Scaffold domain tree

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/docs-domain-scaffold-63ad` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |

**allowed_paths:** `docs/domains/**`, `docs/README.md`, `.agents/plans/docs-domain-reorg-63ad.*`

**Scope:** Create full `docs/domains/<domain>/{features,changes}/` tree for all 10 domains with frontmatter placeholders; AgathaTrack naming in prose.

**Exit criteria:**

- [ ] All 10 domain folders exist with README + features + changes files
- [ ] `validate_docs.sh` passes on new files

---

### Phase 2 — Migrate auth, pet_profile, health_tracking

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/docs-domain-auth-pet-health-63ad` |
| **spawn_allowed** | `true` |
| **exit_checklist** | `default` |

**allowed_paths:** `docs/domains/auth/**`, `docs/domains/pet_profile/**`, `docs/domains/health_tracking/**`, `docs/architecture/pet-activity-model.md`, `docs/experience-program/**`

**Scope:** `git mv` / split per mapping; domain READMEs; lessons/plans indexes linking `.agents/memory/` and `.agents/plans/`.

---

### Phase 3 — Migrate organization

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/docs-domain-organization-63ad` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |

**allowed_paths:** `docs/domains/organization/**`, `docs/architecture/org-*.md`, `docs/org-fostering-strategy.md`, `docs/design/skin-change-guide.md`, `docs/experience-program/**`

**Scope:** Organization identity, permissions, privacy, branding rules; split foster workflow content to fostering in phase 4.

---

### Phase 4 — Migrate fostering and remaining domains

| Field | Value |
|-------|-------|
| **id** | `4` |
| **branch** | `cursor/docs-domain-fostering-rest-63ad` |
| **spawn_allowed** | `true` |
| **exit_checklist** | `default` |

**allowed_paths:** `docs/domains/fostering/**`, `docs/domains/weight_tracking/**`, `docs/domains/vet/**`, `docs/domains/sharing/**`, `docs/domains/notifications/**`, `docs/domains/subscription/**`, `docs/domains/help_about/**`, `docs/fostering-platform/**`, `docs/experience-program/**`

**Scope:** Fostering platform docs; seed weight_tracking and vet journeys/specs from BDD + architecture index; sharing, notifications, subscription, help_about.

---

### Phase 5 — Debt split and cross-cutting deferred

| Field | Value |
|-------|-------|
| **id** | `5` |
| **branch** | `cursor/docs-domain-debt-split-63ad` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |

**allowed_paths:** `docs/domains/**/changes/deferred.md`, `docs/debt/deferred.md`, `docs/debt/technical-debt.md`, `docs/debt/refactoring-debt.md`, `docs/archived/**`

**Scope:** Split debt rows into domain `changes/deferred.md` + `docs/debt/deferred.md`; archive or redirect old debt files.

---

### Phase 6 — Link fixes, index rewrite, verify

| Field | Value |
|-------|-------|
| **id** | `6` |
| **branch** | `cursor/docs-domain-links-index-63ad` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |

**allowed_paths:** `docs/**`, `README.md`, `AGENTS.md`, `.cursor/**`, `.github/**`, `CONTRIBUTING.md`

**Scope:** Grep-fix broken links; rewrite `docs/README.md`; update `docs/architecture/index.md` domain map links; run `validate_docs.sh`.

---

## Runtime state

```yaml
autonomy: completed
current_phase: null
last_completed_phase: 6
halt_reason: null
next_action: "plan complete"
artifact_ref:
  branch: main
  plan_path: .agents/plans/docs-domain-reorg-63ad.md
  plan_commit: ad509f1d124dda1f663e424bdaa400b79a1d70ba
  snapshot_path: .agents/plans/docs-domain-reorg-63ad.snapshot.json
  snapshot_commit: ad509f1d124dda1f663e424bdaa400b79a1d70ba
open_prs: []
merge_commits: {"1":"4cd540999fab1ccbe2cba9c22fadf9acdf5b24ea"}
debt_issue_refs: []
```
