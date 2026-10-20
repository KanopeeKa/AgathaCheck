# WP8 scope sandbox

## Goal
Live verification fixtures for execute-plan-scope (WP8 step 4). Nothing in this plan is intended to merge to main.

## Phases

### Phase 1 — Scope fixtures
```json
{
  "allowed_paths": [".agents/plans/wp8-scope-probe-marker.txt"],
  "forbidden_paths": [],
  "allowed_exceptions": [],
  "companions": ["docs/architecture/openapi/*.json"],
  "exit_checklist": ["WP8 fixtures (a)–(f) recorded on control issue"]
}
```
Scope: update `.agents/plans/wp8-scope-probe-marker.txt` only when exercising in-scope paths.
Out of scope: production code, `.github/workflows`, and all other paths.

## Proof on UAT
Not applicable — sandbox only; no UAT deployment.
