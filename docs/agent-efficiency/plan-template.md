---
title: Plan Template
owner: Documentation Team
audience: both
status: active
last_updated: 2026-11-01
tags: [agent-efficiency, policy]
---
# Plan template — execute-plan v2

Author plans as `.agents/plans/<plan_id>.md` only. The snapshot JSON is **generated** by
`init` — do not hand-write or edit `.snapshot.json`.

**Layout:** [execute-plan-v2/contracts.md](./plans/execute-plan-v2/contracts.md) §3.2 · **Example:**
[`.agents/plans/_example.v2.md`](../../.agents/plans/_example.v2.md) · **Procedure:**
[`.cursor/skills/execute-plan/SKILL.md`](../../.cursor/skills/execute-plan/SKILL.md)

**Sizing:** Medium features that fit one integration branch and the default budgets. If scope is
uncertain, split into a second plan id rather than expanding paths mid-run.

---

## Authoring workflow

1. Branch `cursor/<plan_id>-init` from `main`.
2. Copy the skeleton below into `.agents/plans/<plan_id>.md` and fill it in.
3. Run `node scripts/execute_plan_runtime.js init <plan_id> [--window-days N]`.
   - Default window: **7** days (`approved_until`).
   - Cap: **14** days (`--window-days` cannot exceed the cap in code).
4. Commit and push the init branch; end the planning session with the **exact approval line** printed by `init`.
5. Owner posts that line on the control issue (label `plan:<plan_id>` is added at init).

Optional: `init --dry-run` validates the markdown and prints the snapshot and approval line without
creating an issue or pushing.

---

## Plan file skeleton

Replace placeholders; keep heading names and phase heading pattern.

````markdown
# <title>

## Goal
<One paragraph: outcome, why phased, integration → main → UAT.>

## Phases

### Phase 1 — <phase title>
```json
{
  "allowed_paths": ["path/glob/**"],
  "forbidden_paths": [],
  "allowed_exceptions": ["tests"],
  "companions": [],
  "exit_checklist": ["measurable check 1", "pre-push-changed green"]
}
```
Scope: <what to build or change — concrete deliverables.>
Out of scope: <explicit exclusions.>

### Phase 2 — <phase title>
```json
{ "allowed_paths": ["…"], "forbidden_paths": ["…"], "allowed_exceptions": ["docs"],
  "companions": [], "exit_checklist": ["…"] }
```
Scope: …
Out of scope: …

## Proof on UAT
<How a human verifies the result on https://uat.agathatrack.com — curl, UI path, or E2E note.>
````

### Phase JSON fields

| Field | Required | Notes |
|-------|----------|-------|
| `allowed_paths` | yes | Glob paths under repo root; no overlap across phases unless `spawn_allowed` (use `/spawn-sprint-agents` outside v2 plan file). |
| `forbidden_paths` | no | Extra deny list (`.github/workflows/**` is always protected). |
| `allowed_exceptions` | no | Subset of `tests`, `docs`, `file-split`, `governance-allowlist`, `spawn-integration`. |
| `companions` | no | Paths that may change with the phase without counting as scope violations (see contracts). |
| `exit_checklist` | yes | Short strings the worker uses as done criteria; include `pre-push-changed green` when code changes. |

### Markdown rules

- Phase headings: `### Phase <id> — <title>` with an em dash (U+2014) between single spaces; ids `1`, `2`, … in order.
- The first fenced ` ```json ` block after each phase heading is parsed with `JSON.parse` (no YAML).
- **Forbidden headings** anywhere in the file: `Contract`, `Rules`, `Process` — `init` fails with
  `plan file must not contain process rules`. Process belongs in skills and code, not plan files.
- After approval, the plan bytes are immutable (`plan_file_sha256` in `approval_hash`). Scope changes → new `plan_id` and new `init`.

---

## Branches (created by runtime, not in the markdown)

| Artifact | Pattern |
|----------|---------|
| Init | `cursor/<plan_id>-init` |
| Integration | `cursor/<plan_id>-integration-<suffix>` |
| Phase *n* | `cursor/<plan_id>-p<n>` |
| Release | integration → `main` (one PR) |
| Remedial | `cursor/<plan_id>-remedial-<n>` → `main` (UAT stage only) |

Phase PRs target the integration branch; one release PR merges integration to `main`. The driver
merges — workers and humans do not babysit plan PRs.

---

## Budgets (snapshot defaults, overridable at init)

Defaults from `V2_DEFAULTS` in `scripts/lib/execute_plan_constants.js` (each value ≤ `V2_CAPS`):

| Budget | Default | Cap |
|--------|---------|-----|
| `window_days` | 7 | 14 |
| `ci_per_phase` | 3 | 3 |
| `launches_per_phase` | 5 | 6 |
| `remedial_rounds` | 3 | 3 |
| `sync_attempts` | 2 | 2 |
| `daily_launches` | 20 | 30 |

Raising a budget above its cap fails validation. After STOP, owner **`resume-autonomous`** with the
**same** approval hash renews time and budgets (see runbooks §7.5).

---

## Canonical docs and `changes/`

List canonical feature doc(s) each phase will update in **Scope** or **Goal**. Workers run
`/canonical-docs sync` before push when behaviour changes.

If a proposal is needed before delivery, use `docs/domains/<domain>/changes/<name>.md` with
`status: proposed` and fold into the canonical doc before the programme completes (deletion guard in
`.cursor/skills/canonical-docs/SKILL.md`).

---

## Owner: approve, pause, resume, revoke

| Action | How |
|--------|-----|
| **Approve** | Post the exact `approve-autonomous <plan_id> sha256:… until …` line from `init`. |
| **Pause merges** | Label **`execute-plan-hold`** on the relevant plan PR. |
| **Hard stop on a PR** | Label **`do-not-merge`** on that PR. |
| **Revoke programme** | Label **`autonomous-revoked`** or comment **`revoke-autonomous <plan_id>`**. |
| **Resume after STOP** | Fix cause; remove `needs-owner` / revoke; comment **`resume-autonomous <plan_id> sha256:<same> until <ISO≤14d>`**. |
| **Kill switch** | Set repository variable **`EXECUTE_PLAN_DRIVER=off`**. |

Detail: [runbooks-proof-retirement.md §7.5](./plans/execute-plan-v2/runbooks-proof-retirement.md).

---

## Pre-flight checklist (planner)

- [ ] Plan id is unique and matches filename `.agents/plans/<plan_id>.md`.
- [ ] Every phase has JSON with `allowed_paths` and `exit_checklist`; Scope and Out of scope lines present.
- [ ] No forbidden process headings; paths do not overlap across phases.
- [ ] **Proof on UAT** is observable after release deploy.
- [ ] `init --dry-run` succeeds before the real `init`.
- [ ] Window days chosen (default 7; max 14).

After `init`: owner approves on the control issue; driver takes over — no babysit skills on plan PRs.
