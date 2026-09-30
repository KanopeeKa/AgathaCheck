---
title: Handover supplement — ARCH gates D–G (active-codebase-completion-e41f)
owner: Agent
audience: agent
status: active
last_updated: 2026-09-30
---

# Supplement: gates D–G only

**Canonical procedure** remains [`.agents/plans/active-codebase-completion-e41f.handoff.md`](https://github.com/KanopeeKa/AgathaCheck/blob/claude/friendly-davinci-5zcxj2/.agents/plans/active-codebase-completion-e41f.handoff.md) on `claude/friendly-davinci-5zcxj2` (§0–§11). This file is a **delta** as of **2026-09-30 ~22:15 UTC** — do not duplicate the full playbook.

## Driver

- **Cursor Cloud** is the sole ARCH execute-plan driver (Claude session ended; trigger `trig_01GH4Y6o9g1E9DrSSm5NKquv` deleted).

## Gate D — landed

| Item | Value |
|------|--------|
| PR | [#1467](https://github.com/KanopeeKa/AgathaCheck/pull/1467) |
| Merge SHA | `ce702c0927134416858a5aa7cac17f45d7795289` |
| Control issue | #1447 — runtime `complete-plan` run; close issue when bookkeeping PR merges |
| Roadmap | Child D **merged** in `.agents/plans/active-codebase-completion-e41f.snapshot.json`; `next_child_plan_id` = **E** |

**Pre-UAT on `ce702c09`:** workflow run [36781958843](https://github.com/KanopeeKa/AgathaCheck/actions/runs/36781958843) shows `BUILD_RESULT` and `E2E_RESULT` **success**, but the gate job exited because **`main` advanced to `a340e15` (#1470 TEST phase 6) during the run** (same pattern as #1459 run 565). Not a shard regression from Batch D. Wait for a **stable** `main` tip with green pre-UAT before the next ARCH landing.

**Parallel landings while D was in flight:** #1459, PEOPLE hotfixes #1462/#1464, TEST #1468/#1470, CARE fixes on `main` — integration PR needed repeated `gh pr update-branch` + CI before squash-merge.

## Gate E — not bootstrapped

| Item | Detail |
|------|--------|
| Slot | **3a** — after **CARE A+B** (#1448, `claude/eager-edison-mf34j6`) on `main` + green pre-UAT |
| CARE today | #1448 still **draft**; CI was green before further CARE commits on `main` |
| Approval | Roadmap window ends **2026-10-01T22:39:00Z**. **E will almost certainly start after that** → fresh `approve-autonomous active-codebase-completion-e41f` on **#1446**, re-stamp roadmap snapshot, `--fix-hash`, then bootstrap §6 of canonical handover |
| Prep | Re-read `server/lib/care/**` and `server/routes/healthEntries/**` on `main` at bootstrap (CARE B engine + recent CARE fixes) |

## Gate F — blocked

| Item | Detail |
|------|--------|
| Slot | **5a** — after ARCH **E** and **PEOPLE server** (slot 4) |
| PEOPLE server | Not on `main`; plans on `main` under `.agents/plans/people-server-7f3b.*` |

## Gate G — blocked

| Item | Detail |
|------|--------|
| Slot | **7** — after **CARE E+F** (5b) |
| Note | Re-baseline Package 8 against CARE F Care Item module before G.2/G.3 (canonical handover §5) |

## Coordination (busy `main`)

- **One landing at a time** + pre-UAT green on that merge SHA before opening the next integration → `main` PR.
- **Slot 0c** PEOPLE hotfixes: #1462, #1464 landed; plan bookkeeping followed on `main`.
- **TEST** slice 1 (#1455) landed early; shards and governance evolved on `main` while D was merging — D only **adds** governance steps; keep TEST-owned shard runner/manifest when resolving `pre-push.sh` conflicts.
- Do **not** PR People refetch work from `cursor/preuat-fix-f04e19aa-e41f` — PEOPLE programme owns `features/people/**`.

## Quick status commands

```bash
git fetch origin main
node scripts/execute_plan_runtime.js roadmap-status active-codebase-completion-e41f
gh pr view 1448 --json state,isDraft,mergeable
gh run list --workflow pre-uat-e2e.yml --branch main --limit 3
```

## Bookkeeping branch

Plan snapshot updates + this supplement + review status rows: branch `cursor/arch-d-g-handover-26ff` (open PR to `main` when ready).
