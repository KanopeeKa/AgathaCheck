---
title: Notifications v2 foundation (spec 2.3.1 + main)
owner: Agent
audience: agent
status: active
---

# notifications-v2-foundation-7f3b

## Goal

Apply **rev 2.3.1** documentation fixes and merge the accepted Notifications v2 spec + aligned domain docs to **`main`** before any PR1 code. Unblocks agents reading D7/D8 supersession from `main`.

## Autonomy

| Field | Value |
|-------|-------|
| **Grant keyword** | `approve-autonomous notifications-v2-foundation-7f3b` |
| **Parent** | `notifications-v2-roadmap-7f3b` (standing grant) |

**base_branch:** `main` (both phases target `main` directly — no integration branch yet).

## Phases

### Phase 1 — Spec rev 2.3.1

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/notifications-v2-spec-231-7f3b` |
| **exit_checklist** | `governance` |

**allowed_paths:**

```
docs/domains/notifications/**
docs/domains/cross-domain/changes/program-contract.md
docs/domains/people/features/people-care-team.md
docs/domains/subscription/**
docs/debt/debt.md
.agents/plans/notifications-v2-foundation-7f3b.*
.agents/plans/notifications-v2-roadmap-7f3b.*
```

**forbidden_paths:**

```
flutter_app/**
server/**
db/migrations/**
.github/workflows/**
```

**Scope (2.3.1 checklist):**

- [ ] Spec header: remove stale “Moves to accepted only once…” sentence; status **accepted (rev 2.3.1)**
- [ ] `notification-decisions.md` §B: mark **D9/D10** amended (or “see §C”) like D7/D8
- [ ] `features/specs.md`: remove “panel filter chips” line; point to tabs
- [ ] Spec §3.1: `care` retired wording = archive **due/overdue only**, reclassify rest
- [ ] FR-MG-5: **N1–N13**
- [ ] Badge §5.4.1 prose: Activity count = needs-response + urgent + **unanswered A1**
- [ ] **FR-IA-1** extend: A1 (`This was me` / `Secure my account`), A9 (`Update payment`) — assign PR4 vs PR7 explicitly in FR-IA table
- [ ] §3.4: **`shareLinkFollowed`** (new type) instead of mapping share link → `shareInviteAccepted`; headline template + migration row
- [ ] §3.5 / FR-ACC: **Secure my account** — revoke other sessions only; **renew current session** after password change (today password change revokes all)
- [ ] §3.5: pointer that **device_label** DPIA + erasure documented in PR7 security note (path in programme doc)
- [ ] Rev 2.3.1 entry in spec §15 changelog

**Exit criteria:**

- [ ] `node scripts/check_docs_links.js` (or repo docs check) passes
- [ ] No contradictions between §0, §3.4, FR-SG-4 (S7 owner-only; S1–S6 owner + co-parent + Full access)

### Phase 2 — Merge to main

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/notifications-v2-spec-231-7f3b` |
| **exit_checklist** | `governance` |

**Scope:**

- [ ] Rebase on `origin/main`; incorporate any doc fixes from `origin/claude/jolly-allen-cxrzgc` if not already present
- [ ] Open PR → **`main`** (docs-only); body **Related to** notifications v2 (no standalone `Fixes #N` on migrations)
- [ ] `/babysit-plus` → merge
- [ ] After merge: tag control issue — **foundation complete; bootstrap PR1**

**Exit criteria:**

- [ ] `notifications-v2-spec.md` on `main` at rev 2.3.1+
- [ ] `notification-decisions.md` §C on `main`
- [ ] AC-MG-5 checklist items still `[x]` where applicable

## Runtime

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "continue phase 1 on branch cursor/notifications-v2-spec-231-7f3b"
artifact_ref:
  branch: main
  plan_path: .agents/plans/notifications-v2-foundation-7f3b.md
  plan_commit: 6f4b43687cdf91ecdcd25231758c6f352a06f9cd
  snapshot_path: .agents/plans/notifications-v2-foundation-7f3b.snapshot.json
  snapshot_commit: 6f4b43687cdf91ecdcd25231758c6f352a06f9cd
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
