# People domain refactor — roadmap (`people-domain-refactor-7f3b`)

| Field | Value |
|-------|-------|
| **plan_id** | `people-domain-refactor-7f3b` |
| **plan_kind** | `roadmap` (parent orchestrator; four child execute-plans below) |
| **title** | One authoritative People context (server + Flutter) with a rich, calm UI |
| **programme_ref** | [docs/domains/people/changes/people-domain-refactor.md](../../docs/domains/people/changes/people-domain-refactor.md) (target model, gap analysis, UI spec, decisions R-01…R-14, bugs B1–B13) |
| **coordination** | [docs/agent-efficiency/parallel-programmes.md](../../docs/agent-efficiency/parallel-programmes.md): landing order, area ownership and rebase rules shared with CARE, ARCH and TEST. **Binding for every child.** |
| **author** | Claude Code session 2026-09-29 (People review → target model → Cursor review → coordination pass) |
| **created** | 2026-09-29 (revision 2: split into four children after Cursor's review and the parallel-programme survey) |
| **base_branch** | `main` (each child owns its own integration branch, or targets `main` directly for the hotfix child) |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

---

## Goal

Deliver the People target model in four independently landable slices. Each slice lands on `main` in its slot of the shared landing order, so it never fights CARE (`care-next-occurrence-c1a7`), ARCH (`active-codebase-completion-e41f`) or TEST (`test-health-ci-5f3a`) for the same files.

| Order | Child `plan_id` | Outcome | Landing slot ([parallel-programmes §4](../../docs/agent-efficiency/parallel-programmes.md)) | Entry gate: must already be on `main` | Integration branch |
|---|---|---|---|---|---|
| 1 | `people-hotfixes-7f3b` | Six cheap People bugs fixed now (B1, B2, B5, B7, B9, B13), each with a regression test | slot 0c, right after the docs PR (People-owned files only; disjoint with ARCH D) | docs PR (slot 0b) | none (phase PRs → `main`) |
| 2 | `people-server-7f3b` | Server: single writer, access policy, usage-aware delete, relationships source of truth with vet projection, read models, household directory, invites linked to contacts | slot 4 | CARE A+B (2b) and ARCH E (3a) | `cursor/people-server-integration-7f3b` |
| 3 | `people-client-core-7f3b` | Client: typed core and façade, components and picker, hub, detail, edit, add flow, household UI, E2E for those | slot 5c (People-owned client files; disjoint with ARCH F and CARE E+F) | `people-server-7f3b` and CARE C+D (3b) | `cursor/people-client-core-integration-7f3b` |
| 4 | `people-client-integration-7f3b` | Consumers use the façade and picker, People around {pet}, legacy deleted, E2E for integrations, docs shipped | slot 8 | `people-client-core-7f3b`, CARE E+F (5b) and ARCH G (7) | `cursor/people-client-integration-integration-7f3b` |

**Why four and not one:** the People client needs the care UI and pet profile to settle first (CARE, ARCH G), but most of it doesn't touch them. Splitting lets the hotfixes, the server and the People-owned screens land weeks earlier. Every slice ships its own E2E, so Playwright never lags behind for long.

---

## How to run

### Pre-bootstrap gate (human + agent, before any approval)

1. **Artifacts on `main`.** Docs PR [#1454](https://github.com/KanopeeKa/AgathaCheck/pull/1454) has merged (`eee5cb1b`). Slot **0b** is closed (pre-UAT green on that SHA). It carries:
   - this roadmap, the four child plans and snapshots;
   - the target doc and `parallel-programmes.md`;
   - the stale-plan closure;
   - the refreshed People README, delivery plan, API reference and refactoring log.

   From then on, every branch is created from `origin/main`. No step copies files from a session branch.
2. **No overlapping live plan.** No other execute-plan whose gate could still pass may overlap `server/lib/people/**` or `flutter_app/lib/features/people/**`. "Could still pass" means `autonomy: active`, `approved_until` in the future, and an open control issue with `autonomous-approved`. At 2026-09-29 the only two such plans, `people-vet-unify-a58d` and `contacts-detail-parity-fcd9`, were closed as completed; see the [ledger](./README.md) § Closed stale plans. Re-check with:
   ```bash
   for f in .agents/plans/*.snapshot.json; do node -e '
     const d=require("./"+process.argv[1]); if(d.autonomy==="active" && new Date(d.approved_until)>new Date())
       console.log(d.plan_id, d.control_issue)' "$f"; done
   ```
3. **Landing order confirmed.** The CARE, ARCH and TEST sessions have received their deltas from [parallel-programmes §6](../../docs/agent-efficiency/parallel-programmes.md) (or the human has ruled otherwise).

### Roadmap control issue and grant

```bash
node scripts/execute_plan_runtime.js init-control-issue people-domain-refactor-7f3b
# run the rendered `gh issue create`. Its autonomous-approved label does NOT start anything:
# the gate refuses while the snapshot says autonomy "halted" (checked: exit 2).
```

The human approves with **one comment** on the roadmap issue. The comment is the standing grant for all four children and must restate the pre-approved changes below (Cursor review, challenge 6):

```text
approve-autonomous people-domain-refactor-7f3b
Pre-approved: migrations *_people_relationship_slots (incl. idempotent dedupe of duplicate active slot rows),
*_people_household_notes, *_share_invite_contact_link, *_household_invites; household email invites (server + UI);
the behaviour changes listed in the roadmap; additive `code` field on People error JSON. Renewals at child boundaries.
```

The orchestrator then does the following:

1. Stamps `approved_at` / `approved_until` (+48h) / `approved_by` / `control_issue` / `autonomy: active` in this snapshot.
2. Runs `--fix-hash` and validates.
3. Bootstraps the next child whose entry gate is met:
   ```bash
   CHILD=$(node scripts/execute_plan_runtime.js roadmap-next-child people-domain-refactor-7f3b)
   # verify the child's entry gate on origin/main (commits/PRs listed in its plan); if not met → halt human_pause with next_action
   git fetch origin main && git push origin origin/main:refs/heads/<child integration branch>   # not for people-hotfixes-7f3b
   node scripts/execute_plan_runtime.js init-control-issue "$CHILD"                           # run the rendered gh command
   # child snapshot: control_issue, approved_at, approved_until (+48h), approved_by ("standing grant — roadmap people-domain-refactor-7f3b #<n>"), autonomy active
   node scripts/validate_execute_plan_snapshot.js --fix-hash .agents/plans/$CHILD.snapshot.json
   node scripts/execute_plan_runtime.js roadmap-set-child people-domain-refactor-7f3b --child "$CHILD" --status in_progress --write
   ```
   Then run `/execute-plan $CHILD`.
4. Closes each child after its `main` merge is pre-UAT green: `complete-plan <child> --write`, then `roadmap-set-child … --status merged --pr-url … --merge-commit … --write`. It posts the landing broadcast from [parallel-programmes §7](../../docs/agent-efficiency/parallel-programmes.md) on every open programme control issue.

**Waiting and renewals.** A child whose entry gate isn't met yet is **not** started early. The roadmap halts with `human_pause`, and `next_action` names the missing landing. When the roadmap's 48h window has passed (expected between children, since the gates depend on other programmes), the next child waits for a fresh `approve-autonomous people-domain-refactor-7f3b` on the roadmap issue. Each child has its own 48h window. Agents never extend an expired window themselves and never widen a child to catch up.

---

## Locks (bind every child; do not reopen during a run)

1. Product decisions D1–D28 ([people-care-team.md](../../docs/domains/people/features/people-care-team.md)) are unchanged. Wording follows [vocabulary.md](../../docs/domains/people/features/vocabulary.md): EN nav **Contacts**, FR **Autour de vos animaux**, Trusted carers / Pet professionals, and the desk exception **Vet team**.
2. Engineering decisions R-01…R-14 (target doc §6):
   - People is authoritative; `vets` / `pets.vet_id` are projections.
   - The server computes group, status, usages and access.
   - Kind is explicit, never re-inferred.
   - Delete is usage-aware.
   - Household UI lives in People.
   - One picker.
   - No new dependencies.
   - List–detail uses a ShellRoute with URL state.
   - API changes are additive only.
3. Destructive actions only in **Edit → danger zone**; every removal lists what remains (D16).
4. **Inactive** is neutral, **Needs review** is a warning chip, and errors never show raw backend text.
5. The People error `code` is an **additive** field on the existing `{ error }` envelope; shared `publicError` and validation conventions are untouched.
6. **Coordination rules** ([parallel-programmes §5](../../docs/agent-efficiency/parallel-programmes.md)):
   - one landing at a time;
   - rebase after every broadcast;
   - never edit another in-flight programme's area;
   - migrations by name, numbered at landing;
   - shared E2E files append-only;
   - OpenAPI in the same PR as routes;
   - run the pre-UAT shards for the areas touched.
7. **Conventions from ARCH:** one Flutter entrypoint per feature (`features/people/people.dart`, ARCH D20); new server transaction code uses the shared helper from ARCH E (no hand-written `BEGIN`); Flutter data code follows ARCH H's port/transport convention once published.

## Pre-approved schema and behaviour changes

| Change | Child · phase | Notes |
|---|---|---|
| Migration `*_people_relationship_slots` (+ down) | server · s3 | `sort_order`; partial unique active-slot indexes for `primary_vet`, `out_of_hours_vet`; **idempotent dedupe** of duplicate active slot rows (keep most recently updated; log count) |
| Migration `*_people_household_notes` (+ down) | server · s5 | New table only |
| Migration `*_share_invite_contact_link` (+ down) | server · s6 | Nullable column + index |
| Migration `*_household_invites` (+ down) | server · s6 | New table (pattern of `planned_absence_carer_invites`) |
| Household email invites (API, email template, landing route, UI) | server · s6, client-core · c7 | Closes the documented gap in `householdService.js` ("invite tokens ship in a later phase") |
| PATCH contact never re-infers kind | hotfixes · h1 | B2 |
| PATCH rejects name/email change on a linked contact (`409 linked_identity_read_only`) | server · s1 | D9 / I11 |
| DELETE contact: `409 contact_in_use` + usages; vet-linked unused contacts deletable | server · s2 | B3, B10 |
| Care item `provider_contact_id` validated (`400 validation_failed`) | server · s2 | B12 |
| Household member removal: transactional; last organiser names a successor (`409 successor_required`) | server · s5 | Spec § Tiers and organisers |

Migration **numbers** are assigned when the child's integration → `main` PR is opened: the next free number on `main`, renumbered on rebase if taken ([parallel-programmes §5.5](../../docs/agent-efficiency/parallel-programmes.md)). **Anything else** is a halt with `escalation`: another migration or data change, a breaking response change, a CI workflow edit, a new dependency, or a frozen-domain path.

## Hand-offs to other programmes

| To | What | Why |
|---|---|---|
| CARE (child B) | Record the occurrence provider snapshot from the care item's attached contact **without** filtering by the completer's directory (invariant I12, bug B6) | CARE B rewrites the completion commands before `people-server-7f3b` starts; `s2` adds only the façade validation and regression tests on top |
| ARCH (child E) | Drop `server/routes/pets/peopleRelationshipsRouter.js` from E's `allowed_paths` | `s3` rewrites it on the shared transaction helper |
| ARCH (child F) | Include `people_contacts`, private and household notes, `household_invites`, `pet_share_invites.contact_id` and contact links in the F.1 personal-data inventory | These tables land in `people-server-7f3b`, before F |
| ARCH (child H) | Publish the Flutter port/transport convention early | `c1` adopts it, so H converts nothing twice |
| TEST (phases 2–3) | Run the short PR CI tier for PRs into integration branches | People children otherwise rely on local shards only |

---

## Orchestrate phase (this roadmap's only phase)

| Field | Value |
|-------|-------|
| **id** | `orchestrate` |
| **branch** | `cursor/people-refactor-orchestrate-7f3b` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `governance` |

**allowed_paths:**

```
.agents/plans/people-domain-refactor-7f3b.md
.agents/plans/people-domain-refactor-7f3b.snapshot.json
.agents/plans/people-hotfixes-7f3b.md
.agents/plans/people-hotfixes-7f3b.snapshot.json
.agents/plans/people-server-7f3b.md
.agents/plans/people-server-7f3b.snapshot.json
.agents/plans/people-client-core-7f3b.md
.agents/plans/people-client-core-7f3b.snapshot.json
.agents/plans/people-client-integration-7f3b.md
.agents/plans/people-client-integration-7f3b.snapshot.json
docs/domains/people/**
docs/agent-efficiency/parallel-programmes.md
```

**forbidden_paths:**

```
.github/workflows/**
server/**
flutter_app/**
e2e/**
db/**
```

**allowed_exceptions:** `docs`

**Scope:**

- Bootstrap children in order when their entry gates are met.
- Track them with `roadmap-set-child`.
- Post landing broadcasts.
- Keep `parallel-programmes.md` §1 (programme states) current for People rows.

---

## Runtime state (agent-updated)

```yaml
autonomy: halted
current_phase: orchestrate
last_completed_phase: null
halt_reason: human_pause
next_action: "human_pause: wait for CARE 2b + ARCH 3a on main, fresh approve-autonomous on #1460, then resume-plan and bootstrap people-server-7f3b"
artifact_ref:
  branch: cursor/people-refactor-orchestrate-7f3b
  plan_path: .agents/plans/people-domain-refactor-7f3b.md
  plan_commit: a436175f8c55caba2a8cd031b9450cef5f9ab6d5
  snapshot_path: .agents/plans/people-domain-refactor-7f3b.snapshot.json
  snapshot_commit: a436175f8c55caba2a8cd031b9450cef5f9ab6d5
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Sanity check

**Expectation:** `proceed-high-risk`.

- Four children, each within one 48h window: hotfixes about 3h, server about 12–16h, client-core about 14–18h, client-integration about 8–12h of agent time.
- Authorization work in `s1`, `s2`, `s4`, `s5`, `s6` (R3). Four additive migrations, one with an idempotent dedupe.
- External gates on three children, so expect `human_pause` halts between children and roadmap renewals.

## Revoke and resume

| Action | How |
|--------|-----|
| **Revoke** | `autonomous-revoked` on the roadmap or child control issue; optional `do-not-merge` on open PRs. Halt only. |
| **Resume** | Remove the label; comment `resume-plan <plan_id>`; `/execute-plan <plan_id> resume` |
