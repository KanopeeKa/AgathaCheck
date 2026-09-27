# People & Care Team — execute-plan

**plan_id:** `people-care-team-a58d`  
**title:** People directory, households, and absence access (spec phases 0–4)  
**created:** 2026-09-27  
**base_branch:** `cursor/people-care-team-integration-a58d` (implementation); phase `land-docs` targets `main`  
**default_merge_mode:** `auto`  
**artifact_branch_policy:** `phase-branch`

## Goal

Land the agreed People & Care Team documentation on `main`, then implement product phases 0–4 from [people-care-team.md](../../docs/domains/people/features/people-care-team.md) with phase PRs into the integration branch and one final integration → `main` PR after phase 4.

**Standing grant (user chat 2026-09-27):** full autonomous execute-plan — no per-phase approval; implement until phase exit criteria met; include doc-branch tidying (merge to `main`).

## Autonomy

| Field | Value |
|-------|-------|
| **approved_by** | user chat 2026-09-27: execute-plan full autonomous power through phases 0–4 |
| **control_issue** | #1343 |

## Runtime

```yaml
autonomy: active
current_phase: p4-guest-access
last_completed_phase: p3-households
halt_reason: null
next_action: "continue phase p4-guest-access on branch cursor/people-p4-guest-a58d"
artifact_ref:
  branch: cursor/people-p4-guest-a58d
  plan_path: .agents/plans/people-care-team-a58d.md
  plan_commit: a6c2b028031e3f72564893d78dd18b6dbef82f8e
  snapshot_path: .agents/plans/people-care-team-a58d.snapshot.json
  snapshot_commit: a6c2b028031e3f72564893d78dd18b6dbef82f8e
open_prs: []
merge_commits: {"land-docs":"5515e1ed0f4475d0a2a6d1a4d9b2d71fb33c5bef","p0-model":"e5eb27e4e064a69963cfa630b75ebc556bac2d5a"}
debt_issue_refs: []
```

## Phases

### Phase land-docs — Land spec on main

**branch:** `cursor/people-docs-land-a58d`  
**targets:** `main`  
**Scope:** People domain docs from `claude/friendly-hopper-la0gx7` (commits through `e09a851`), cross-links, `amends-away-planning.md`.

**Exit criteria:**

- [ ] PR merged to `main`
- [ ] `bash scripts/validate_docs.sh` green on `main`

### Phase p0-model — Delivery plan + contact schema

**branch:** `cursor/people-p0-model-a58d`  
**Scope:** `docs/domains/people/changes/delivery-plan.md`; DB migrations for contact identity/relationship/private-note tables (D11); document carer fact `unset | set | unavailable` in api-reference; no product UI.

**Exit criteria:**

- [ ] Delivery plan lists file ownership per product phase 1–4
- [ ] Migrations apply on dev DB; Jest migration test passes
- [ ] api-reference documents new tables and carer wire shape (planned fields)

### Phase p1-contacts — Contacts v1

**branch:** `cursor/people-p1-contacts-a58d`  
**Scope:** People screen (carers/professionals); migrate `vets` → contacts + primary-vet relationship; OOH vet + emergency contacts; care item provider; logged/performed by + snapshots; account link schema unused in UI; interim CASCADE rule (D11 phase 1 note).

**Exit criteria:**

- [ ] Vet BDD scenarios pass; new people API Jest coverage
- [ ] Flutter analyze + unit tests for people feature
- [ ] `note_only` unchanged until p2

### Phase p2-absence — Absence integration

**branch:** `cursor/people-p2-absence-a58d`  
**Scope:** Carers from contacts; migrate `note_only` rows; carer `unavailable`; looked-after-by on absence; PDF extras per spec; D28 behaviour.

**Exit criteria:**

- [ ] Away planning BDD green; migration for carer rows
- [ ] Handover PDF includes vets/emergency per spec

### Phase p3-households — Households

**branch:** `cursor/people-p3-households-a58d`  
**Scope:** Household CRUD, tiers, pet membership, access evaluation, removal flows, contact copy D23, who-has-access + audit cap 100, guarded account deletion.

**Exit criteria:**

- [ ] Sharing/household Jest + BDD updates
- [ ] No new user CASCADE to shared data

### Phase p4-guest-access — Absence guest access + timezone

**branch:** `cursor/people-p4-guest-a58d`  
**Scope:** User timezone on account + absence (D24); invite-for-absence flow (D8/D19); time-bound access; D16 confirm on widen.

**Exit criteria:**

- [ ] Timezone stored and copied on absence create
- [ ] Guest access E2E or BDD path for invite + expiry

### Phase integration-main — Integration → main

**branch:** `cursor/people-care-team-integration-a58d`  
**targets:** `main`  
**Scope:** Final merge PR only (after p4 merged to integration).

**Exit criteria:**

- [ ] `./scripts/pre-push.sh` green
- [ ] `/babysit-uat` pre-UAT green on merge SHA
