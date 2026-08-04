# Plan — Organisation UX v3

| Field | Value |
|-------|-------|
| **plan_id** | `organisation-ux-v3-badd` |
| **title** | Organisation UX v3 — visibility, chrome, profile nav, privacy, upload fix |
| **base_branch** | `cursor/organisation-ux-v3-integration-badd` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |
| **control_issue** | #567 |

## Goal

Deliver Organisation UX v3 per [`docs/experience-program/organisation-ux-v3-delivery-plan.md`](../../docs/experience-program/organisation-ux-v3-delivery-plan.md): show-org toggle + last-section login, org chrome, dashboard/discover IA, profile nav-rows (no previews), Account per-org privacy, people tiles, upload P0, then integration→main and pre-UAT green loop.

**Canonical detail:** that delivery plan (phases 0–12, decisions D-v3-*, deferred DEF-*). This file is the execute-plan index.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | `2026-08-04T17:02:58Z` |
| **approved_until** | `2026-08-06T17:02:58Z` |
| **autonomy** | `active` (standing grant 2026-08-04) |
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
autonomy: active
current_phase: 12
last_completed_phase: 11
halt_reason: null
next_action: "continue phase 12 on branch cursor/organisation-ux-v3-integration-badd"
artifact_ref:
  branch: cursor/organisation-ux-v3-integration-badd
  plan_path: .agents/plans/organisation-ux-v3-badd.md
  plan_commit: 52d52f4c2a2c93e7fb62a7bbe21c362ab601f7ca
  snapshot_path: .agents/plans/organisation-ux-v3-badd.snapshot.json
  snapshot_commit: 52d52f4c2a2c93e7fb62a7bbe21c362ab601f7ca
open_prs: ["https://github.com/KanopeeKa/AgathaCheck/pull/583"]
merge_commits: {"0":"d70ee21aae3c3754cc7887a9a21d1b4b21755e72","1":"135c3ee703f65ff46dac9ee692eda578f1d6788b","2":"3feee757e54493a6a44a908177c122e81dfb6de7","3":"f3bbe62f82de413b8ed297872c9951235effd9ab","4":"6ee3a07f6397dfbd82c1302323e79e5556b429c8","5":"868200ec03b0a26ee1642ba77197fd8dae36df25","6":"9ac075be183cbe663beaa9217b79a195b073d0ef","7":"541f6c6ecf197c7251fb49f787cdb540e045abad","8":"c7892e588136270c6822d898c0f10919ad987273","9":"69f95f0e59b36a3e786632ff7c5deaaa730dde92","10":"1660d2d2f76be22d38b151f1a2d871b1c18c7ae0","11":"b29e3addeafb57d65b99ebc3c1b405b78a71b646"}
debt_issue_refs: [568,569,570]
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
