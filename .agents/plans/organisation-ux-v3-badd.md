# Plan — Organisation UX v3

| Field | Value |
|-------|-------|
| **plan_id** | `organisation-ux-v3-badd` |
| **title** | Organisation UX v3 — visibility, chrome, profile nav, privacy, upload fix |
| **base_branch** | `cursor/organisation-ux-v3-integration-badd` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |
| **control_issue** | _(set by `init-control-issue`)_ |

## Goal

Deliver Organisation UX v3 per [`docs/experience-program/organisation-ux-v3-delivery-plan.md`](../../docs/experience-program/organisation-ux-v3-delivery-plan.md): show-org toggle + last-section login, org chrome, dashboard/discover IA, profile nav-rows (no previews), Account per-org privacy, people tiles, upload P0, then integration→main and pre-UAT green loop.

**Canonical detail:** that delivery plan (phases 0–12, decisions D-v3-*, deferred DEF-*). This file is the execute-plan index.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | _(at grant)_ |
| **approved_until** | `approved_at + 48h` |
| **autonomy** | `halted` until `approve-autonomous organisation-ux-v3-badd` |
| **sanity** | `proceed-high-risk` — prefer mid-run re-approve or split `v3a` (0–6) / `v3b` (7–12) if window tight |

**Grant keyword:** `approve-autonomous organisation-ux-v3-badd`

## Phases (summary)

| ID | Title | Exit checklist | Spawn |
|----|-------|----------------|-------|
| `0` | Decisions, docs, debt issues | governance | no |
| `1` | Org image upload P0 | single-backend-route | no |
| `2` | Show-org toggle + last section | bdd-journey | no |
| `3` | Org-area chrome | flutter-screen-split | no |
| `4` | Dashboard tiles + Discover row | bdd-journey | no |
| `5` | Discover screen + search + browse-as | bdd-journey | optional |
| `6` | Profile header / edit / menus | bdd-journey | no |
| `7` | Profile nav rows + Administration | bdd-journey | no |
| `8` | Account per-org privacy + Leave | bdd-journey | no |
| `9` | People directory tiles | bdd-journey | optional |
| `10` | Connected orgs + pets entry | bdd-journey | no |
| `11` | Hardening l10n / BDD / seeds | bdd-journey | no |
| `12` | Integration → main + pre-UAT loop | default | no |

Full `allowed_paths` / branches: `.agents/plans/organisation-ux-v3-badd.snapshot.json`.

## Runtime state

```yaml
autonomy: halted
current_phase: null
last_completed_phase: null
halt_reason: "awaiting approve-autonomous organisation-ux-v3-badd"
next_action: "init-control-issue → human approve → /execute-plan organisation-ux-v3-badd"
artifact_ref:
  branch: null
  plan_path: .agents/plans/organisation-ux-v3-badd.md
  plan_commit: null
  snapshot_path: .agents/plans/organisation-ux-v3-badd.snapshot.json
  snapshot_commit: null
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Bootstrap

```bash
git checkout -b cursor/organisation-ux-v3-integration-badd origin/main
# merge plan docs PR first if needed
node scripts/validate_execute_plan_snapshot.js .agents/plans/organisation-ux-v3-badd.snapshot.json
node scripts/execute_plan_runtime.js init-control-issue organisation-ux-v3-badd
# human: approve-autonomous organisation-ux-v3-badd on control issue
# then: /execute-plan organisation-ux-v3-badd
```
