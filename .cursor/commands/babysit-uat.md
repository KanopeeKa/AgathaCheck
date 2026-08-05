---
name: babysit-uat
description: Babysit+ merge plus pre-UAT E2E gate on main with risk-ranked local shard replay. Use for final merge to main.
---

# Babysit-UAT

Read and follow **`.cursor/skills/babysit-uat/SKILL.md`**.

## Quick start

```bash
# After PR is ready (or to run end-to-end):
# 1. /babysit-plus through merge (embedded in skill)
# 2. Risk check
node scripts/babysit_uat_shard_risk.mjs --pr <n>
# 3. Watch YOUR merge commit only
./scripts/babysit_uat_watch_preuat.sh <merge_sha> --json
```

## Rules

1. **One remedial PR** per pre-UAT failure wave — no stacked patches
2. **Round 1:** high-risk shards → act immediately; low/medium → wait for CI
3. **Round 2+:** wait for CI failure before local runs
4. **Shard fix:** Task subagent per failure; main keeps running shards
5. **Exit:** pre-UAT green for merge SHA — **not** deploy/prod-ready

Policy: `docs/agent-efficiency/autonomous-pr-policy.md` · Parent: `/babysit-plus`
