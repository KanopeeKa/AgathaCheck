# Proof run: UAT build label (rerun)

## Goal
Prove execute-plan v2 end to end after the 7f3a fixes: two phases on an integration branch, one
release PR to main, Pre-UAT E2E, promotion and Deploy UAT, with no owner message after the approval
comment. Drills are run by a drill agent using the `execute-plan-hold` label.

## Phases

### Phase 1 — Server build label
```json
{ "allowed_paths": ["server/bin/server.js", "server/test/healthProofLabel.test.js"],
  "forbidden_paths": [], "allowed_exceptions": ["tests"], "companions": [],
  "exit_checklist": ["health proof-label test green", "pre-push-changed green"] }
```
Scope: in the `GET /backend/health` handler, change `proof_label` to `execute-plan-v2-proof-2`
(keep `status: 'OK'`); update `server/test/healthProofLabel.test.js` to assert the new value.
Out of scope: `/health`, any other route, any Flutter file.

### Phase 2 — Docs note
```json
{ "allowed_paths": ["docs/e2e/uat-deploy-tiers.md"],
  "forbidden_paths": [], "allowed_exceptions": ["docs"], "companions": [],
  "exit_checklist": ["docs gates green"] }
```
Scope: under the section "Execute-plan v2 observes this chain", add one line below the existing
7f3a line: `Proof run: proof-build-label-7f3b (2026-11-01)`.
Out of scope: everything else.

## Proof on UAT
`curl -s https://uat.agathatrack.com/backend/health | jq -r .proof_label` prints `execute-plan-v2-proof-2`.
