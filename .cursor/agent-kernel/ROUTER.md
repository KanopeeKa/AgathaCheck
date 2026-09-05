# Engineering Router

Classification layer for Tier 1 Cursor workflows. **Read this file** at skill start, resolve risk + protocols, then read **only** the listed protocol files under `.cursor/agent-kernel/protocols/`.

**Not a replacement for:** execute-plan runtime, atomic PR policy, PR hygiene, pre-push scripts, or path-scoped `.mdc` rules. Rules supply ambient constraints while editing; protocols supply **task** checklists.

**Canonical human guide:** `docs/engineering/cursor-agent-framework.md`  
**Scenario fixtures:** `docs/engineering/router-scenarios.md`

---

## Router profiles (per Tier 1 skill)

Use the profile named in each skill preamble — do not run full classification when a lighter profile applies.

| Profile | When | Steps |
|---------|------|-------|
| **full** | New implementation work; execute-plan phase start; babysit-plus implementing a fix | Inspect → classify → risk → protocols → verify map |
| **diff-scoped** | Existing PR triage/merge; babysit-uat | Changed files + PR diff → risk floor → minimal protocols |
| **classify-first** | e2e-debug | Preflight → failure class → conditional Router |
| **design-scoped** | ui-design-deep | UI surfaces → risk → a11y/mobile/testing; API/security only if contract impact |

| Skill | Default profile | Modes |
|-------|-----------------|-------|
| `/execute-plan` | **full** at phase select + plan strengthen; **skip strengthen** on resume-only (babysit/CI/watch) |
| `/babysit-plus` | **full** when implementing; **diff-scoped** when PR-only triage/CI/merge |
| `/babysit-uat` | **diff-scoped** (+ existing shard-risk scripts) |
| `/e2e-debug` | **classify-first** |
| `/ui-design-deep` | **design-scoped** |

---

## Procedure (full profile)

### 1. Inspect (depth scales with risk)

| Starting signal | Minimum inspect |
|-----------------|-----------------|
| User task / plan phase | Stated goal + `allowed_paths` / diff |
| R0 fast path (below) | Changed files only |
| R1 | Changed files + immediate callers/tests |
| R2+ | + schema, auth helpers, API consumers, domain docs |

Read `docs/architecture/index.md` before broad search. Do not classify from filenames alone.

### 2. Classify domains & surfaces

**Domains:** Pet Care, Shelter, Auth, shared org infrastructure. Pet Care sub-areas: profile, health, weight, vets, sharing, fostering, notifications, timeline.

**Surfaces (cumulative):** Flutter UI/state/networking, backend routes, domain logic, AuthN, AuthZ, public endpoints, persisted data, health/sensitive data, DB/schema/migration, file storage, sharing tokens, recurrence/dates, dependencies, CI, observability, docs, E2E.

### 3. Assign risk (R0–R3)

**Default:** start at **R1**; escalate after inspection.

#### R0 — trivial / non-behavioural

Copy, doc typo, harmless visual tweak, comment/test rename. No API behaviour, auth, or persisted-data semantics.

#### R1 — ordinary localized change

Local UI, internal refactor without contract change, straightforward domain logic.

#### R2 — cross-boundary or sensitive (behaviour changed)

**Floors** when behaviour actually changes: external API, AuthZ, validation of persisted input, health/sharing/uploads, DB schema, mobile networking, notifications, shared Pet Care/Shelter infrastructure.

#### R3 — critical infrastructure

Auth/session architecture, token rotation, central AuthZ, private health storage, destructive migration, account/pet deletion, custody transfer, public sharing security model, crypto/secrets, large data migration.

#### Escalation triggers (minimum risk)

| Signal | Floor |
|--------|-------|
| Persisted user data semantics | R2 |
| External API behaviour | R2 |
| Authorization rules | R2 |
| Sensitive health data | R2 |
| Schema migration | R2 |
| Auth/session infrastructure | R3 |
| Private sensitive storage | R3 |
| Destructive migration | R3 |
| Ownership/custody transfer | R3 |

Tasks may escalate during implementation — load protocols without asking the user to restart.

#### R0 fast path (all must be true)

1. Single concern: copy, comment, typo, or harmless visual tweak  
2. No `server/routes/**`, migrations, auth, uploads, sharing, or API/client contract files  
3. No persisted-data or AuthZ semantics  
4. Inspect = changed files only  

If any doubt → R1 minimum.

### 4. Resolve protocols (cumulative)

Read only protocols listed for your surfaces. Path-scoped rules (e.g. `security.mdc` on `server/**`) may already apply — run the **protocol sections** still required (e.g. AuthZ negative tests), do not re-read entire doctrine.

| Actual change | Protocols |
|---------------|-----------|
| Auth/session/JWT | security, testing, flutter-mobile, documentation, observability |
| Pet access/roles | authorization, security, testing |
| API request/response | api-contract, validation, testing, flutter-mobile |
| New endpoint | security, authorization, validation, api-contract, testing, documentation |
| DB/schema | database-and-migrations, testing |
| Persistent sensitive data | security, data-lifecycle, testing |
| Health data | authorization, validation, security, testing |
| Health documents | private-files, authorization, security, data-lifecycle, api-contract, testing |
| Sharing/public token | authorization, security, data-lifecycle, api-contract, testing |
| Pet/account deletion | data-lifecycle, database-and-migrations, private-files, testing |
| Flutter networking | flutter-mobile, api-contract, testing |
| Meaningful Flutter UI | accessibility, flutter-mobile, testing |
| Notifications/recurrence | date-time, flutter-mobile, testing |
| Dependency addition | dependency-review, security |
| Bug fix | testing (regression) |
| Security bug | security, testing (negative regression) |
| Public endpoint | security, api-contract |
| Major backend ops change | observability |
| Significant architecture | documentation |
| Major user journey / release | release-verification |

### 5. Verification map

Map `verification[]` to existing commands — do not invent parallel checklists.

| Verification | Command / artifact |
|--------------|-------------------|
| Changed-file gate | `./scripts/pre-push-changed.sh` |
| Full merge gate | `./scripts/pre-push.sh` |
| Route unit tests | `cd server && npx jest --env=node --forceExit test/<domain>/` |
| Flutter analyze | `cd flutter_app && flutter analyze --no-fatal-warnings --no-fatal-infos` |
| Flutter tests | `cd flutter_app && flutter test --concurrency=1 …` |
| E2E shards | `./scripts/pre-push-changed.sh --e2e-shards <n>` |
| Phase exit | `docs/agent-efficiency/phase-exit-checklists.md` profile |
| UI quick pass | `accessibility` protocol §Quick pass |
| File size | `node scripts/check_file_size.js` |
| BDD gate | `node e2e/scripts/check_bdd_coverage.js` |

---

## Execute-plan: strengthen ≠ scope creep

Router may discover missing engineering work. It must **not** silently widen an atomic phase.

1. Annotate phase/plan: `router_risk`, `protocols[]`, `verification[]`, `phase_fit`  
2. If requirements fit the phase outcome → include  
3. If additional independent outcome → **split phase** (update snapshot `allowed_paths`)  
4. Resume-only sessions → skip strengthen; continue `next_action`

---

## Shared architecture ownership

Domain workers may **consume** but must **not** independently redefine: authentication, authorization, validation conventions, API error model, session semantics, storage abstraction, audit conventions, public API shape.

Changes to shared patterns → shared-foundation phase. See `.cursor/rules/agent-coordination.mdc`.

---

## Enforcement honesty

| Kind | Examples |
|------|----------|
| **CI-enforced** | file size, BDD coverage gate, npm audit high+, Jest in CI |
| **Agent-required** | AuthZ negative tests, OpenAPI sync, protocol checklists |
| **Convention** | ADRs, domain docs |
| **Future** | OpenAPI drift CI, real-DB AuthZ matrix in CI |

---

## Protocol index

| ID | File |
|----|------|
| security | `.cursor/agent-kernel/protocols/security.md` |
| authorization | `.cursor/agent-kernel/protocols/authorization.md` |
| api-contract | `.cursor/agent-kernel/protocols/api-contract.md` |
| validation | `.cursor/agent-kernel/protocols/validation.md` |
| database-and-migrations | `.cursor/agent-kernel/protocols/database-and-migrations.md` |
| private-files | `.cursor/agent-kernel/protocols/private-files.md` |
| data-lifecycle | `.cursor/agent-kernel/protocols/data-lifecycle.md` |
| testing | `.cursor/agent-kernel/protocols/testing.md` |
| flutter-mobile | `.cursor/agent-kernel/protocols/flutter-mobile.md` |
| accessibility | `.cursor/agent-kernel/protocols/accessibility.md` |
| date-time | `.cursor/agent-kernel/protocols/date-time.md` |
| documentation | `.cursor/agent-kernel/protocols/documentation.md` |
| dependency-review | `.cursor/agent-kernel/protocols/dependency-review.md` |
| observability | `.cursor/agent-kernel/protocols/observability.md` |
| release-verification | `.cursor/agent-kernel/protocols/release-verification.md` |
| e2e | `.cursor/agent-kernel/protocols/e2e.md` |
