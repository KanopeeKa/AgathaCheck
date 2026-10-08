---
title: Documentation migration roadmap (SUPERSEDED)
owner: Documentation Team
audience: agent
status: retired
last_updated: 2026-10-08
---

# SUPERSEDED — use `documentation-migration-514a`

This roadmap orchestrator is **retired**. Use the unified execute-plan instead:

- **Plan:** `.agents/plans/documentation-migration-514a.md`
- **Snapshot:** `.agents/plans/documentation-migration-514a.snapshot.json`
- **Control issue:** [#1787](https://github.com/KanopeeKa/AgathaCheck/issues/1787)
- **Command:** `/execute-plan documentation-migration-514a`

Child `plan_id`s under `documentation-migration-*-514a` remain in git history only; do not run gate or bootstrap on them.
