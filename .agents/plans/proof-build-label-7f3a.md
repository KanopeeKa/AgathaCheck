# Proof run: UAT build label

## Goal
Prove execute-plan v2 end to end: two phases on an integration branch, one release PR to main,
Pre-UAT E2E, promotion and Deploy UAT, with no owner message after the approval comment.

## Phases

### Phase 1 — Server build label
```json
{ "allowed_paths": ["server/bin/server.js", "server/test/healthProofLabel.test.js"],
  "forbidden_paths": [], "allowed_exceptions": ["tests"], "companions": [],
  "exit_checklist": ["health proof-label test green", "pre-push-changed green"] }
```
Scope: in the `GET /backend/health` handler, add the JSON field `proof_label` with the constant
value `execute-plan-v2-proof` (keep `status: 'OK'`); add `server/test/healthProofLabel.test.js`
asserting both fields with `supertest` and `createApp(mockPool())`.
Out of scope: `/health`, any other route, any Flutter file.

### Phase 2 — Docs note
```json
{ "allowed_paths": ["docs/e2e/uat-deploy-tiers.md"],
  "forbidden_paths": [], "allowed_exceptions": ["docs"], "companions": [],
  "exit_checklist": ["docs gates green"] }
```
Scope: add one line under the section "Execute-plan v2 observes this chain":
`Proof run: proof-build-label-7f3a (2026-10-28)`.
Out of scope: everything else.

## Proof on UAT
`curl -s https://uat.agathatrack.com/backend/health | jq -r .proof_label` prints `execute-plan-v2-proof`.
