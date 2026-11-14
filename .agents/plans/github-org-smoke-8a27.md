# GitHub org migration — execute-plan smoke (dry-run)

## Goal

Validate approve workflow and driver kill-switch semantics on the org-owned repository while
`EXECUTE_PLAN_DRIVER=dry-run`. No product delivery; owner revokes after section 5.9 evidence is recorded.

## Phases

### Phase 1 — Runbook smoke marker
```json
{
  "allowed_paths": ["docs/ops/github-org-migration-runbook.md"],
  "forbidden_paths": [],
  "allowed_exceptions": ["docs"],
  "companions": [],
  "exit_checklist": ["runbook §5.9 evidence line present", "pre-push-changed green"]
}
```
Scope: when the runbook file exists on `main`, append one line under §5.9 recording smoke pass date and
control issue number. If the file is not on `main` yet, skip implementation (driver dry-run only).
Out of scope: any workflow, secret, ruleset, or product code change.

## Proof on UAT

N/A — infrastructure smoke only.