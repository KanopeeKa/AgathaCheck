---
title: Handover supplement — ARCH gates D–G (active-codebase-completion-e41f)
owner: Agent
audience: agent
status: active
last_updated: 2026-10-04
---

# Supplement: gates D–G only

**Canonical procedure:** [`.agents/plans/active-codebase-completion-e41f.handoff.md`](https://github.com/KanopeeKa/AgathaCheck/blob/claude/friendly-davinci-5zcxj2/.agents/plans/active-codebase-completion-e41f.handoff.md) on `claude/friendly-davinci-5zcxj2` (§0–§11). This file is a **delta** — do not duplicate the full playbook.

**Also linked from:** [`.agents/plans/active-codebase-completion-e41f.md`](./active-codebase-completion-e41f.md) §Runtime state.

## Driver

- **Cursor Cloud** is the sole ARCH execute-plan driver (merge authority for programme PRs under execute-plan).
- Roadmap autonomy renewed **2026-10-04** on [#1446](https://github.com/KanopeeKa/AgathaCheck/issues/1446) (`approve-autonomous active-codebase-completion-e41f`); snapshot `approved_until` **2026-10-06T13:40:59Z**.

## Gate D — landed

| Item | Value |
|------|--------|
| PR | [#1467](https://github.com/KanopeeKa/AgathaCheck/pull/1467) @ `ce702c09` |
| Bookkeeping | [#1471](https://github.com/KanopeeKa/AgathaCheck/pull/1471) |
| Control issue | #1447 (closed) |

## Gate E — in progress (bootstrapped 2026-10-04)

| Item | Value |
|------|--------|
| Control issue | [#1492](https://github.com/KanopeeKa/AgathaCheck/issues/1492) |
| Integration branch | `cursor/active-codebase-e-integration-e41f` (from current `main`) |
| Landing slot | **3a** (`parallel-programmes.md`) |
| Entry gates met | ARCH D on `main`; CARE **2b** [#1448](https://github.com/KanopeeKa/AgathaCheck/pull/1448) merged 2026-10-01; CARE **3b** [#1475](https://github.com/KanopeeKa/AgathaCheck/pull/1475) also on `main` |
| Next work | Phase 1 → `cursor/active-codebase-e1-cleanup-jobs-e41f` (re-read `server/lib/care/**` and health entry routes on `main` before coding) |
| PEOPLE boundary | `peopleRelationshipsRouter.js` is **not** in E paths (PEOPLE server s3); allowlist-only in E.3 transaction test until then |

**Integration → `main` PR:** open only when no other programme landing is in flight and pre-UAT is green on the current `main` tip.

## Gate F — blocked

Slot **5a** — after ARCH **E** and **PEOPLE server** (slot 4). Plans: `.agents/plans/people-server-7f3b.*`.

## Gate G — blocked

Slot **7** — after **CARE E+F** (5b). Re-baseline Package 8 against CARE F before G.2/G.3.

## Coordination

- One landing on `main` at a time; pre-UAT green on that merge SHA before the next.
- Do **not** PR People refetch from `cursor/preuat-fix-f04e19aa-e41f` — PEOPLE owns `features/people/**`.
- GitHub plan labels for long plan ids may exceed 50 characters; gate checks use `execute_plan_runtime.js gate … --labels` (see #1492: `execute-plan`, `autonomous-approved`).

## Quick status

```bash
git fetch origin main
node scripts/execute_plan_runtime.js roadmap-status active-codebase-completion-e41f
node scripts/execute_plan_runtime.js gate active-codebase-completion-e41f --labels execute-plan,plan:active-codebase-completion-e41f,autonomous-approved
gh run list --workflow pre-uat-e2e.yml --branch main --limit 1
```
