---
title: Active codebase architecture review
owner: Engineering
audience: both
status: accepted
last_updated: 2026-09-22
peer_reviewed: 2026-09-22
tags: [architecture, review, modularity, pet-care]
---
# Active codebase architecture review

## Executive assessment

**Verdict:** retain the Flutter/Riverpod + Node/Express modular monolith. Improve module contracts, state ownership and transaction boundaries; do not rewrite the application or introduce microservices.

The repository already has feature-oriented organization, domain repository ports in several features, composed backend routers, centralized access/capability policies, useful contract tests, and considerable governance documentation. The weakness is that folder boundaries are not consistently API boundaries: consumers import feature internals, state can have multiple owners, and route/application/persistence responsibilities vary between domains.

### Main priorities

1. **Correct transaction and command-result semantics first.** Pet data deletion uses pool queries for a transaction; some commands can commit successfully and subsequently return an error because follow-up work fails.
2. **Define public feature contracts and enforce dependency direction.** Static analysis found 50 directed cross-feature edges, with 12 features in one strongly connected component. This is a coarse module graph, not proof that every class participates in a cycle.
3. **Give each mutable client resource one canonical state owner.** Health entries currently have independently fetched and global-derived views; cache failures can conceal the distinction between offline data and authorization failures.
4. **Turn written rules into executable architecture checks.** Frozen-boundary scans, size gates, lint coverage and coverage denominators are narrower than their apparent repository-wide claims.
5. **Document components, not just folders and endpoints.** Specify owned data, public symbols, errors, allowed dependencies, side effects, and compatibility policies alongside each component.

### Baseline and change constraints

- Review date: 2026-09-22.
- Reviewed commit: a8c7db1be2e493f10623e6b9a37fced0b7a31d0c.
- Feature branch: replit/preuat-adoption-pets-e7d3d1d.
- Report only: no production code, dependencies, runtime settings, database or main-branch changes are authorized by this review.
- Relevant declared dependencies: Dart ^3.12.0, flutter_riverpod ^2.6.1, go_router ^14.8.1; Node ESM, Express ^4.18.2, pg ^8.23.0. These are manifest constraints, not claims that every installed version equals its lower bound.
- Shelter and Fostering internals are excluded. Shared active infrastructure and active-to-frozen seams are included. Retained frozen data still has privacy/export/deletion obligations.

## Methodology and evidence quality

The approved benchmark is a domain-oriented modular monolith with selective ports-and-adapters principles. Review activities included repository-wide tracked-source inventory, a static Flutter import/export/part graph, server entrypoint reachability approximation, code-size measurement, detailed frontend/backend flow inspection, and governance/documentation inspection. Independent reviews covered Flutter, backend, governance, and metrics; high-risk findings were cross-checked against source.

A full architecture review is not an exhaustive correctness/security audit. All active feature roots received structural inventory; deeper behavioral inspection concentrated on auth, pet profiles, care entries/occurrences, sharing, lifecycle/erasure and their shared infrastructure. Smaller features were assessed structurally and through their dependencies, not every method. No new runtime tests, full test suite, production probes or database queries were run for this report. Earlier rebase validation is historical context only, not a fresh passing test claim.

Evidence labels:
- **Confirmed implementation:** directly visible in reviewed code; no claim of observed production impact.
- **Risk:** a failure or maintenance consequence inferred from the implementation; needs a characterization/fault-injection test.
- **Recommendation:** a proposed target, not an existing interface.

Priorities: P1 = integrity/boundary or high-change-risk work to address first; P2 = next structural improvement; P3 = incremental refinement. P0 is reserved for an established emergency; this review does not establish one. Effort bands are planning estimates: S = localized change, M = one flow/module with tests, L = coordinated multi-module migration. They are not delivery-time promises.

## Benchmark and primary sources

Sources retrieved on 2026-09-22:

1. [Flutter architecture recommendations](https://docs.flutter.dev/app-architecture/recommendations): separate UI/data responsibilities, repositories, dependency injection, isolated and integrated component tests. A domain/use-case layer is conditional, not mandatory for every operation. Retain Riverpod rather than replacing it merely because the guide illustrates another DI mechanism.
2. [Riverpod DO/DON'T](https://riverpod.dev/docs/root/do_dont): statically declared providers, avoid write side effects in provider initialization, keep route-local ephemeral state local. Current docs include experimental newer features; do not prescribe Riverpod 3 Mutations for this Riverpod 2 repository.
3. [node-postgres transactions](https://node-postgres.com/features/transactions): every statement in a transaction must use the same client; pool.query is not a transaction boundary.
4. [Express error handling](https://expressjs.com/en/guide/error-handling.html): explicit async error propagation and centralized HTTP error translation. Apply Express 4-compatible patterns here; do not assume Express 5 promise rejection behavior.
5. [Node packages and exports](https://nodejs.org/api/packages.html): explicit package exports can define public interfaces when package separation is justified. For this single server package, first enforce local import rules; package exports alone do not stop relative-path bypasses.
6. [OpenAPI specification](https://spec.openapis.org/oas/latest.html): machine-readable operations, request/response schemas and errors. Use a version supported by this repository's tooling, not an automatic upgrade to the latest specification.

Gold-standard in this context means enforceable ownership and contracts, not more layers. Avoid automatic microservices, CQRS/event sourcing, universal interfaces, blanket repository wrappers over trivial queries, or file splitting just to meet an arbitrary number.

## Current and target component model

### Current architecture, simplified

~~~mermaid
flowchart LR
  UI[Flutter screens and widgets] --> State[Riverpod providers and controllers]
  State --> Ports[Domain repository ports]
  Ports --> Data[HTTP and local adapters]
  UI -. some direct calls .-> Data
  UI -. commands coordinated in widgets .-> Ports
  Data --> HTTP[Express router composers]
  HTTP --> Services[Application services and shared libraries]
  HTTP -. some SQL and business orchestration .-> DB[(PostgreSQL)]
  Services --> DB
  Services --> Effects[Files / email / notifications / audit]
~~~

### Component catalog and recommended public seams

This table describes architectural responsibilities; it does not claim that each proposed public seam already exists. Exact measured feature sizes are in Appendix D.

| Component | Subcomponents / owned responsibility | Current entry or seam | Recommended boundary and documentation priority |
|---|---|---|---|
| Authentication | session restoration, credentials, token storage, authenticated principal | AuthNotifier, AuthService; auth session/profile/password routers | AuthRepository + SessionStore ports; document refresh/logout and erasure semantics |
| Pet profiles | profile records, list/detail/form, lifecycle | PetRepository, pet providers; pets composer and subrouters | PetProfiles query/command API; export stable DTOs, not screens; separate lifecycle use cases |
| Health tracking | entries, issues, schedule occurrences, attachments | HealthRepository and health providers; healthEntries routers | one canonical entries store; CareScheduleController; attachment port |
| Weight tracking | observations, weight entry and schedule linkage | weight data/presentation and completion API | WeightObservation commands; schedule integration mediated by a use case |
| Care taxonomy | category/action vocabulary | taxonomy feature consumed by care/profile | immutable vocabulary/value objects; prevent taxonomy depending on UI internals |
| Care intelligence | derived recommendations and context | care_intelligence + backend care libraries | query/projection API over owned inputs; no mutation authority in suggestions |
| Pet Care | away plans, carers and care context | pet_care/context and careContext routers | CareContext query/command API; document temporal and access rules |
| Experience | dashboard, responsive shell, navigation composition | experience widgets/providers, app router | composition layer consuming feature public view models; domain modules must not depend on its screens |
| Sharing/access | invites, links, co-parent/carer grants | sharing services + db/sharing queries; pet capability libraries | invitation commands, authorization policy API; transaction ownership explicit |
| Notifications | notification feed, read state, navigation targets | notification providers + helper/service | notification command/query contract; durable delivery only where required |
| Vets | directory/contact relationships and selection | VetRepository + vet feature exports | public model/port and selected UI entrypoints; data implementations stay internal |
| Tags | personal pet organization | pet_tags feature | user-scoped tag queries/commands; no dependency on shell implementation |
| Subscription | entitlement/paywall and purchase integration | subscription providers and paywall | entitlement query plus purchase adapter; no billing SDK details in consumer features |
| About/help | information and support presentation | about/help routes and widgets | small public route/widget surface; no unnecessary domain layer |
| Shared foundation | HTTP, dates, theme/UI primitives, request context, principal | core and server middleware/lib | explicit owner per utility; do not move domain logic here just to remove a cycle |

Recommended subcomponent hierarchy within a substantial feature:

~~~text
Feature public API (stable models, queries, commands, intentional UI entrypoints)
  Application: controllers/use cases; owns command and transaction orchestration
  Domain: pure policies and value objects where rules justify them
  Adapters: HTTP/database/files/external services; implements required ports
  Presentation: widgets/screens; displays state and invokes commands
  Composition: creates implementations and wires dependencies
~~~

Allowed dependency direction: presentation -> application/public domain contracts; application -> domain and required ports; adapters -> port/domain types; composition -> implementations. Other features import only the public API. A pure design-system widget does not depend on Riverpod feature providers. UI feature entrypoints may be exported intentionally, but data implementations should not be exported by default.

## Prioritized findings and action matrix

| ID | Priority / confidence | Finding and practical consequence | Target / acceptance evidence | Effort |
|---|---|---|---|---|
| A01 | P1 / high | Pet deletion uses pool.query for BEGIN and subsequent statements; atomicity is not guaranteed | mandatory checked-out-client transaction runner; injected failure rolls every DB change back | M |
| A02 | P1 / high | Post-commit follow-up work can turn committed writes into HTTP failures | stable committed result; idempotent replay; durable delivery for required effects | M–L |
| A03 | P1 / high | Active/frozen seams and boundary checker coverage diverge | manifest-driven active graph and route reachability tests, without reviewing frozen internals | M |
| A04 | P1 / high | Feature public APIs do not consistently prevent deep imports or cyclic coupling | explicit entrypoints, permitted-edge manifest, no new cycles; migrate one cycle at a time | L |
| A05 | P1 / medium-high | Independent health-entry fetch/store paths and widget-owned refresh orchestration | one resource authority; controller command; all selectors observe the same mutation result | M |
| A06 | P1 / high | Catch-all pet cache fallback hides authorization/error versus offline/stale state | classify errors; explicit offline policy and freshness metadata | M |
| A07 | P2 / high | Account erasure mixes sequential DB/file/external steps with partial-failure risk | idempotent erasure state machine plus durable external cleanup; fault-injection tests | L |
| A08 | P2 / high | Lifecycle success DTO is ambiguous and lifecycle documentation is internally inconsistent | single canonical command/notification contract; GET-after-command test | S–M |
| A09 | P2 / high | Transaction/auth helpers and transport access are inconsistently centralized | one transaction API, principal/error boundary; retain authorization policy enforcement | M |
| A10 | P2 / high | Size/coverage/BDD/lint gates cover less than readers may infer | explicit measured universes and ratcheted gates; docs and CI agree | M–L |
| A11 | P2 / medium-high | Auth and health attachment presentation depend on concrete data services | introduce ports at actual volatility/test seams; not an interface for every class | M |
| A12 | P3 / high | Large layout/route modules mix several responsibilities below the file cap | extract by use case or cohesive UI subcomponent with explicit inputs/callbacks | incremental |

Detailed evidence and migrations are in Appendices A–C. Findings A01/A02 are implementation-confirmed failure paths, not evidence that production data has already been lost. A03 is a boundary finding: authorized org-transfer routes remain registered; it is not a claim of unauthenticated access.

### Proposed API examples

These sketches are targets, not patches or declarations already present in the repository.

~~~dart
abstract interface class PetProfilesRepository {
  Future<PetSnapshot> list({required PetFetchPolicy policy});
}
// PetSnapshot carries pets, source, isStale and fetchedAt.
// Authentication/permission errors never masquerade as successful offline reads.

abstract interface class HealthDocumentsRepository {
  Future<HealthDocument> upload(UploadHealthDocument command);
  Future<void> remove(HealthDocumentId id);
}

// One controller owns remote command + canonical state reconciliation.
// If commit succeeds but refresh fails, preserve committed success and expose
// a separate refresh/reconciliation status, not a generic "save failed".
abstract interface class CareScheduleCommands {
  Future<OccurrenceCompletion> complete(CompleteOccurrence command);
}
~~~

~~~javascript
// Application service owns the transaction; repositories receive its client.
await transactions.run(async (client) => {
  await petLifecycle.deleteRows(client, command);
  await cleanupJobs.enqueue(client, filesToRemove);
});
// HTTP maps a domain result to an explicit response, never infers rollback
// merely because an after-commit notification or projection refresh failed.
~~~

Use an outbox only for effects whose delivery must survive process failure. Cache invalidation can instead use safe invalidation/rebuild and explicit freshness, depending on its guarantees. Persisting every optional telemetry event in an outbox would add unjustified complexity. Cross-store client updates cannot be made atomic by naming a controller; canonical state plus explicit reconciliation is the actual guarantee.

## Coding and component documentation standard

### Code rules

- Each component states its one primary responsibility and its non-goals.
- Export deliberately: public domain models/ports and intentional UI entrypoints; no blanket exports of adapters.
- Cross-component calls use typed DTOs/results with explicit nullability, identifiers and calendar-date semantics. Avoid unstructured maps beyond serialization boundaries.
- Business authorization belongs on the backend. UI eligibility improves UX but never authorizes writes.
- Controllers/application services own multi-step commands; widgets own rendering and ephemeral interaction state.
- Query/read APIs do not perform hidden remote writes. Cache reads identify stale/offline outcomes.
- One checked-out database client per transaction. Nested operations accept that client rather than starting an independent transaction.
- Distinguish validation, unauthenticated, forbidden, not-found, conflict and transient failures. Map them once at transport boundaries; redact operational details centrally.
- Required external side effects need a retryable/idempotent delivery policy; document the commit point.
- Tests target public contracts and failure semantics, not only internal invocation order.
- Keep Riverpod 2 unless an independently justified migration is approved. No framework replacement is needed for these improvements.

### Size standards

Keep the repository's existing physical-line rules as the current baseline; do not silently replace them with heuristic source-line limits. Publish both measures and their definitions. Proposed review triggers: approximately 300 source lines per file, 500+ requiring justification, 40–50 lines per ordinary method, cyclomatic complexity above 10 and nesting beyond 3–4 levels. These are triage thresholds, not measured complexity scores in this review.

Use role-sensitive checks: a route-registration wrapper contains nested handlers, and Flutter declarative layout naturally spans more lines. Extract a subcomponent only when it owns a coherent responsibility and has a useful input/output contract. Avoid dozens of single-use wrappers with no semantic value. Exceptions should have owner, reason, review date and an expiry/ratchet decision. Extend checks to active server libraries/services and typed UI categories before tightening caps.

### Required component documentation

For each substantial component publish: purpose/non-goals; owned state/data; public entrypoint; exported symbols/endpoints with inputs, outputs and errors; allowed/forbidden dependencies; side effects and transaction owner; cache/freshness policy; permissions; compatibility/deprecation policy; tests and required CI checks; size exceptions; operational behavior; owner and last-reviewed date.

Use ADRs for significant boundary choices (canonical health state, transaction ownership, frozen compatibility adapter), not routine code moves. Keep OpenAPI and consumer contract tests authoritative for wire behavior, and generate/reference endpoint documentation where possible. Appendix C provides a concrete README template.

## Phased roadmap

The accepted initial delivery sequence is **A: protect → B: backend integrity → C: client authority**, not twelve concurrent refactors. Packages 9–12 remain a later program backlog; a narrow baseline/block-new boundary check may start in A, but full API/cycle migration waits for C. Package 5 is a separate privacy workstream with explicit infrastructure prerequisites.

Success measures: fewer forbidden deep imports and strongly connected features; every mutable resource has a named owner; every transaction has a single client; committed writes have unambiguous responses; required side effects have documented replay semantics; contract documentation and checks are executable and current. Line-count reductions alone are not success.

## Accepted decisions and revised delivery sequence

The user accepted the peer decision-table recommendations on 2026-09-22. This section resolves D1–D7 and supersedes alternatives in the historical peer review and evidence appendices. **Accepted** means architecture direction accepted, not implementation completed, tests passed, or permission to merge to main. No runtime changes or persistent execution mission are initiated by this document update.

| Decision | Accepted contract | Implementation constraint / gate |
|---|---|---|
| D1 | Passed-away POST is **notification-only**; pet persistence stays in the separate PUT. | Replace the misleading state claim with `notification_sent` and an explicit delivery status/count. `notification_sent` may be true only for completed delivery, not merely enqueueing. Preserve installed clients through a versioned or negotiated compatibility contract; never silently change endpoint meaning. |
| D2 | **Hybrid offline reads:** 401/403 fail explicitly; genuine network failures may return cached pets with `isStale` and freshness metadata. | Do not classify parse errors, arbitrary 5xx, validation errors or access revocation as offline success. Cache must be scoped to the authenticated principal and invalidated on logout/account changes. |
| D3 | Account erasure returns **202 Accepted plus a durable job**, not synchronous completion. | Return 202 only after durable acceptance; provide truthful pending/failed/completed status. Commit access/session invalidation and cleanup intent before accepting; define how existing access JWTs are rejected, not only refresh tokens. |
| D4 | Minimal **`cleanup_jobs` table** for erasure work and required notifications; no event bus. | External account erasure (including PostHog) is necessary erasure work under D3, not a new generic job platform. Cache refresh, optional audit/telemetry and projections are excluded. Specify delivery guarantees, idempotency, worker ownership, retries and failure handling before producers switch. |
| D5 | **DAG with explicit allowed composition edges.** Experience consumes feature public APIs; domain features do not import Experience screens or another feature's presentation internals. | Allow only named composition entrypoints in Experience and core router/wiring, not blanket `core → *` permission for foundation/domain utilities. An edge allowlist does not excuse a cycle; any temporary cycle exception is separately recorded with expiry. |
| D6 | Baseline existing violations and **block new** violations. | Compare stable violation identities, not just total counts, so one removed violation cannot hide a different new one. |
| D7 | Add `server/lib` size coverage **report-only first**, then ratchet. | Publish grandfathered exceptions with owner/reason/review date before blocking changed/new violations. Do not impose an immediate global split. |

### Delivery batches and stop/go gates

“Sprint” denotes an ordered scope batch, not a promised duration. Each batch can contain several atomic PRs; tests for known defects must land with their fix or be explicitly baseline-classified, never make the required CI suite red indefinitely.

| Batch | Scope and PR boundaries | Entry / exit gate |
|---|---|---|
| **A — Protect** | A1: Package 1 command/compatibility baseline and characterization fixtures. A2: focused Package 2 frozen-command registration fix with its regression tests. A3: manifest-driven checker coverage, separate from the route fix if needed. | No broad refactor. Verify both API prefixes, preserve active individual-transfer/family-history behavior, and baseline current violations rather than demanding their immediate elimination. |
| **B — Backend integrity** | B1: Package 3 transaction runner + pet deletion. B2: Package 4 stable command responses and effect classification. B3: Package 6 notification-only DTO compatibility. | A scenarios defined; real DB rollback/concurrency evidence and installed-client compatibility gate pass before cutover. If required cleanup jobs are not ready, stage them first rather than accepting nondurable cleanup. |
| **Parallel privacy workstream** | Package 5 after D3/D4, the Package 3 transaction runner, and minimal cleanup schema/worker contract are available. Can overlap B2/B3; it is not blocked on optional notification delivery work. | Erasure authorization, immediate access rejection, durable retry and irreversible-operation runbook are required, not a bare 202 response. |
| **C — Client authority** | C1: Package 7 cache policy. C2: Package 8 canonical health owner/controller. Design during B; runtime cutover follows stable B contracts. | Stale/auth distinctions visible in UI; cross-selector, out-of-order response, logout and command-retry tests pass. |
| **Later program backlog** | Packages 9–10 after C validates the pattern; Package 11 ratchets introduced checks; Package 12 selective extraction/final audit. | Prioritize forbidden pet-profile-to-Experience presentation dependencies. Preserve legitimate shell-to-feature API edges; do not remove edges simply to lower a count. |

### Effect classification required before Package 4

| Effect | Consistency requirement | Accepted handling |
|---|---|---|
| Weight observation + occurrence state / required establishment invariant | Same logical command | Same transaction/client; if establishment is derived instead, document reconciliation explicitly. |
| Weight cache refresh | Rebuildable projection | Invalidate/rebuild; separate refresh status, no cleanup job. |
| Invite access/status + required in-app notification row | Atomic when business contract requires it | Same transaction where all data is local; use a required-notification cleanup job only for genuinely asynchronous durable delivery. Prepare names/DTO data before commit or retain a stable committed response. |
| Required external notification/email | At-least-once, potentially duplicate external delivery | Minimal cleanup job, provider idempotency where available, explicit retry/deduplication policy. Optional invitation email remains delivery metadata unless classified required. |
| Pet/account files and external personal-data erasure | Must survive process failure | Persist minimum cleanup identifiers before cascades; cleanup jobs with retry and verified completion. |
| Optional audit/activity/telemetry | Best effort unless a separate obligation makes it required | Catch/report failures without changing committed response; no generic outbox. Mandatory DB audit belongs in the transaction, not an unawaited call. |

### Cross-cutting implementation gates

1. **Installed clients and both prefixes:** Packages 4–7 cannot merge a wire change without a matrix of supported native versions, current web client, strict/missing-field decoding, 200/201/202 handling, and both `/api` and `/backend/api`. Package 7 may keep freshness local to the repository; do not change the server DTO unnecessarily. If supported clients cannot handle a change, introduce a parallel/version-negotiated contract and release clients first. A deprecation date requires actual adoption evidence.
2. **Unknown commit outcomes:** network loss during COMMIT or after a response is not proof of rollback. Retry/reconcile via an operation key and resource identity; do not blindly repeat destructive work. Scope idempotency to principal + operation + payload; same key/different payload is a conflict. Bound retention and define replay authorization after access changes.
3. **Job reliability without a platform rewrite:** additive schema and indexes; atomic job claim/lease; crash recovery; bounded backoff; unique dedupe key; retry exhaustion and operational alerts. A worker crash after external success must be safe to replay. Never cascade-delete cleanup jobs with the user/pet they must erase; store only necessary identifiers, protect status access and expire completed job payloads.
4. **Authorization and races:** transaction correctness does not by itself close access-revocation races or concurrent delete/upload/complete races. Lock or revalidate the relevant resource/access version inside the command boundary; reject writes to deleting resources. Test revocation, concurrent completions, invite expiry/revoke/accept and uploads during deletion.
5. **Acceptance is not completion:** distinguish queued, running, retryable failure, terminal failure and completed states. Do not mark a job complete merely because helpers swallowed errors. A 202 must not cause the UI to claim successful erasure or notification delivery.
6. **Operational rollback:** deploy backward-compatible schema/worker before switching producers. During rollback preserve pending jobs and dedupe records, prevent old synchronous paths plus new workers executing twice, and never restore erased personal data as a rollback tactic.

### Second-pass risk register and required proof

These are implementation design/test requirements, not claims of newly observed production incidents. Evidence refers to the locally reviewed baseline; the historical peer independently checked a later main revision. Rebase/recheck affected flows before implementation.

| Risk / evidence | Required addition and owning package | Acceptance scenario |
|---|---|---|
| **Transaction success is not the same as a delivered response.** Weight commits before cache/establishment work; invite creation commits before lookup/delivery (`completeWeightRouter.js`, `shareInviteService.js`). | P3/P4: define transaction state and preserve original errors; reuse existing schedule idempotency conventions only after checking scope/uniqueness. `care_schedule_events.idempotency_key` already has a unique index in migration 062; do not add a second incompatible ledger by assumption. Document consistent lock order and bounded deadlock retries. | Connection lost during COMMIT; same request retried concurrently; same key with different payload; no duplicate mutation or disclosure of another principal's result. |
| **Delayed cleanup can outlive its parent and storage instance.** Current lifecycle code collects URLs, deletes rows and attempts local filesystem deletion (`petDataLifecycle.js`, `privateHealthStorage.js`). | P3/P5: durable jobs retain stable object/file IDs, not arbitrary executable paths; validate allowed storage roots and symlink/path traversal. Ensure the worker can reach the same storage as the uploader; do not assume another process/container has the same files. No storage migration is authorized by this plan. | Missing object is idempotent success; permission/provider failure is retryable/failed, not success. Reject unsafe paths. Crash after deletion before acknowledgement; two workers; expired lease reclaimed; pending job survives parent cascade. |
| **Minimal job infrastructure still needs ownership.** Existing best-effort helpers cannot report verified erasure. | P3/P4/P5: schema includes type, dedupe key, minimal payload, status, attempts, next attempt, lease token/expiry and redacted error. Claim atomically (e.g. `FOR UPDATE SKIP LOCKED`); only the current lease holder may acknowledge. Define runner lifecycle, alert owner and protected manual retry. | `pending → running → succeeded / retryable / dead`; worker crash at every transition; duplicate workers; retry exhaustion becomes visible. Completed payload retention is bounded. |
| **Notification authorization can change after enqueue.** Collaborators are selected at call time in `notifyPassedAwayCollaborators`; delayed delivery changes the timing. | P4/P6: dedupe by event + recipient; revalidate recipient eligibility before sending private pet content. Define when a required notification is cancelled because access was revoked and expose accurate eligible/sent/queued/cancelled counts. Do not require that a revoked recipient receive private data to satisfy delivery. | Access revoked or account erased between enqueue and delivery; repeated/concurrent POST; zero recipients; partial delivery; no persisted passed-away state change. |
| **202 erasure can leave a usable account or inaccessible status.** The current sequence revokes refresh sessions before deleting the user (`profileRouter.js`), while middleware verifies JWTs. | P5/P10: erasing-account rejection must be enforced on existing access tokens and refresh/login paths; define protected post-revocation status and retry access. Capture owned/shared data scope before cascades, preserving other users' data and documenting lawful retention. | Old access token and concurrent upload rejected after durable acceptance; duplicate erasure request returns the same operation; status credential cannot access other jobs; shared-pet data is not accidentally erased. |
| **Offline reads are not an offline command queue.** Current health commands call remote operations then refresh (`health_providers.dart`). | P7/P8: no silent offline queue for destructive/auth-sensitive writes. Offline commands fail explicitly; uncertain outcomes reconcile with the original operation key after reconnect. Distinguish local intent, server commit and refresh status in UI. | Offline mutation, reconnect retry, lost response and refresh failure produce distinct user-visible outcomes; retries do not resurrect deleted pets/entries. |
| **Canonical state can still race.** Health mutation methods refetch; separate per-pet/global views currently coexist (`health_providers.dart`). | P8: per-resource serialization/version policy, per-pet loaded/error markers, session-generation guards and safe disposal. Define whether optimistic changes are used; do not overwrite a newer server result with an older GET. Cache and local-persistence failures must not turn a committed command into failure. | Out-of-order reads, simultaneous edits to the same/different entries, late callback after logout, deletion during fetch and cache-write failure. Every selector converges on the same committed result. |
| **Compatibility and baseline rules can silently widen scope.** Mixed transfer router registers individual and org transfer; family-events includes org-specific writes and reads (`transferRouter.js`, `familyEventsRouter.js`). | P2/P11: list routes, callers and response fields before gating. Historical/retained reads are classified, not assumed active or frozen by filename. Store baseline revision and exact violation identities; publish size exceptions, not just totals. | Both-prefix route matrix; active individual transfer preserved; forbidden org mutations unavailable; intentional historical-read policy tested. A different new violation fails even when total violation count decreases. |

**Scope discipline:** complete the contract and failure tests within each owning package; do not create a generic queue framework, offline mutation ledger, new auth platform, storage migration or unrelated refactor to satisfy this register. If a listed operational guarantee cannot be met by the current environment, stop that package's cutover and document the concrete blocker.

## Detailed implementation plan to reach the target state

This is a proposed execution plan, not authorization to refactor or an active mission. Deliver each numbered package as a separately reviewable change on a feature branch. Roles below are ownership responsibilities, not assumptions about team staffing. Keep the application deployable between packages; avoid a repository-wide move/rename PR.

### Sequence and dependencies

| Package | Outcome | Depends on | Suggested owner | Effort |
|---|---|---|---|---|
| 1 | Reproducible baseline and failure contracts | None | Technical lead + QA | M |
| 2 | Enforced active/frozen boundary | 1 | Backend + Flutter | M |
| 3 | Correct transaction ownership and pet deletion | 1 | Backend | M |
| 4 | Stable committed command results | 3 | Backend | M–L |
| 5 | Retryable account and external erasure | 3, D3/D4 and minimal job contract | Backend + privacy owner | L |
| 6 | Notification-only lifecycle wire contract | 1, 4, D1 compatibility gate | API + Flutter | S–M |
| 7 | Explicit pet cache and failure policy | 1 | Flutter | M |
| 8 | Canonical health state and command orchestration | 1, 4 wire contract | Flutter | M–L |
| 9 | Public feature APIs and reduced coupling | 2, 7, 8 for final cutover | Flutter + backend | L |
| 10 | Auth/document ports and consistent transport boundaries | 3, 9 | Flutter + backend | M |
| 11 | Enforced standards and coverage denominators | 1; ratchet alongside 2–10 | Tooling + QA | M–L |
| 12 | Remaining cohesive extractions and final acceptance | 2–11 | Component owners | incremental |

Execute the accepted A → B → C batches above. Design client work during B, but deliver 7 → 8 in C; defer full public-API/cycle work until that pattern is proven. Package 5 can overlap B after its listed prerequisites. Documentation and focused tests accompany every package rather than waiting for 11.

### 1. Freeze the measurement scope and characterize behavior

1. Record the reviewed revision, manifest exclusions, active route-registration approximation and generated/test exclusions in a baseline artifact. Run the Appendix D script and retain machine-comparable file/edge inventories when implementing the gate.
2. Build a command matrix for pet-data deletion, weight completion, invite creation/acceptance, account erasure, and passed-away notification: authorization, transaction owner, commit point, response DTO, replay behavior and external effects.
3. Add focused tests at the current public boundaries. Separate desired-contract regressions from existing-behavior characterization; land regression tests with fixes rather than weakening assertions to pass.
4. Cover mid-delete DB failure, post-commit cache/establishment/name-read failures, invite retry, swallowed external erasure failure, 401/403 versus offline pet fetch, and issue-link/completion visibility in both health read paths.
5. Inventory callers and supported installed-client DTO expectations before changing endpoint names or fields.

**Exit gate:** every P1 finding maps to a named test scenario and owner; measured exclusions are explicit; no existing failing test is described as a new regression without baseline comparison. **Rollback:** this package is additive tests/docs only; it must not change runtime behavior.

### 2. Close active-to-frozen seams without deleting retained data

1. Make boundary checks consume `docs/engineering/frozen-domains/manifest.json`, including `activeSurfacesToRemove`; scan all active Dart and server production roots, not a directory allowlist.
2. Distinguish import-time loading from route registration. Gate prohibited org-transfer and frozen family-event operations/imports as required by the freeze contract. Inventory operations first: a whole-router switch must not disable active individual transfer or family-history behavior. Where mixed, split registration without reviewing frozen internals.
3. Isolate necessary retained-schema access behind an explicitly documented compatibility seam. Keep privacy export/erasure coverage; do not remove tables or historical data. Track retained foster/org DTO fields and their active UI interpretation explicitly; do not silently drop fields from installed clients.
4. Add fixtures for nested routers, re-exports, relative/package Dart imports, permitted compatibility reads and forbidden feature imports. Enumerate actual mounted routes under both API prefixes with frozen mode off.

**Exit gate:** forbidden commands are not mounted when frozen mode is off; authorized active commands still work; retained-data privacy tests pass; intentional exceptions have owner/reason/review date. **Rollback:** revert a faulty boundary implementation without re-enabling frozen commands; retain regression tests and data.

### 3. Establish one transaction owner and repair pet-data deletion

1. Introduce or strengthen one mandatory checked-out-client transaction runner in `server/lib/db`. Acquire once; begin/commit/rollback/release once; preserve the original error if rollback also fails. No pool-only fallback for operations requiring atomicity.
2. Refactor `deleteAllPetData` into application orchestration plus client-taking data operations. Collect file identifiers and delete/update DB rows through that same client.
3. Decide audit guarantees explicitly: optional safe audit is not atomic; a required DB audit record must use the same transaction. Persist required file cleanup in the minimal `cleanup_jobs` schema before deleting the only references to files; this foundational schema/worker contract is a prerequisite to deletion cutover, not deferred entirely to Package 5.
4. Separate DB outcome from cleanup status. Deprecate the misleading interpretation of `files_removed`; count only verified deletions or expose scheduled/completed/failed counts through a compatible DTO evolution.
5. Migrate duplicate transaction helpers incrementally after their consumers have tests; do not change frozen internals as part of the active migration.

**Exit gate:** a real PostgreSQL integration test proves rollback after each failing DB step and client release; a rotating-pool test catches accidental pool queries; cleanup is retryable and counts are truthful. **Cutover/rollback:** use additive cleanup-job storage and compatible responses; a code rollback must not drop pending jobs or restore the pool-based transaction defect.

### 4. Make committed outcomes stable and effects explicit

1. For `completeWeightOccurrence` and `shareInviteService`, separate pre-commit failures from post-commit work. Build the authoritative command result from transaction results, not fallible post-commit display-name reads.
2. Classify weight establishment: if it is a required invariant, persist it in the transaction; if a derived projection, make reconciliation explicit and retryable. Handle cache refresh via invalidation/rebuild without converting a committed write into “save failed.”
3. Apply the accepted effect-classification table before changing invitation notifications/email. Enqueue only required asynchronous durable notifications in `cleanup_jobs` within the transaction; keep optional telemetry best-effort with visible failure metrics. No generic event bus or projection/cache jobs.
4. Implement worker/job retry, bounded backoff, deduplication keys and a failed-job inspection/retry path. Document at-least-once delivery rather than claiming exactly-once external delivery.
5. Preserve existing weight replay semantics and define invite replay/conflict behavior. Validate concurrent requests and retries after a lost response; persist an idempotency result where necessary.

**Exit gate:** fault injection before commit rolls back; after commit, cache/lookup/delivery failures cannot misreport an uncommitted command; concurrent retries do not create duplicate observations/grants. **Cutover/rollback:** deploy additive storage before producers/workers; never discard queued effects on rollback, and prevent old synchronous plus new worker paths delivering twice.

### 5. Make account erasure resumable

1. Map user-owned and shared records, retained frozen data, files and PostHog identifiers with the privacy owner. Define lawful retention exceptions and the minimum metadata needed to retry cleanup.
2. Move account erasure out of `profileRouter` into an application service. Use a transaction for DB erasure/tombstone, session/access invalidation and durable cleanup jobs; external requests must not hold the DB transaction open. Return **202 Accepted** only after this durable acceptance boundary. Reject existing access JWTs and new writes for an erasing account, not merely future refresh attempts.
3. Preserve cleanup identifiers before cascades remove them. Replace swallowed external failure-as-success with tracked pending/failed/completed outcomes.
4. Provide an idempotent authenticated request/result contract and pending/failed/completed status after normal credentials are revoked, using an opaque, narrowly scoped status capability or equivalent protected mechanism. Do not expose another user's deletion status or retain general-purpose access merely to poll. Cover user-facing pending/error/completed states and the installed-client 202 compatibility gate.
5. Test already-deleted files/persons, duplicate requests, worker restarts, provider downtime, late DB failure and shared-pet ownership. Document retry exhaustion and manual remediation.

**Exit gate:** the response distinguishes accepted erasure from completed erasure; failed cleanup can resume without a live account or duplicate destructive effects; privacy/export behavior covers retained data. **Rollback:** erasure cannot be undone; roll back code only while retaining durable cleanup records and a working retry path. Never promise restoration of deleted personal data.

### 6. Reconcile passed-away notification and persistence contracts

1. Inventory Flutter/API callers of `lifecycleRouter` and the separate pet PUT.
2. Implement D1: retain notification-only semantics and separate PUT persistence; do not consolidate into a new lifecycle mutation in this program. Return `notification_sent` plus explicit delivery/count semantics, never `passed_away: true` as a new-contract state claim. Queued required delivery is not yet sent; retries must not duplicate notifications.
3. Remove contradictory stub text in `api-reference.md`, update OpenAPI and return a DTO whose fields match the chosen semantics. Do not silently repurpose an existing endpoint used by installed clients.
4. Test authorization, repeat notification policy, GET after PUT/command, and failure between persistence and notification.

**Exit gate:** docs, DTO and read-after-write behavior agree; POST alone leaves pet persistence unchanged; PUT followed by notification preserves that split; installed-client and both-prefix contract tests pass. **Rollback:** retain an explicit versioned compatibility adapter during the approved window, without silently reinterpreting the endpoint.

### 7. Make pet cache authority visible to clients

1. Define typed fetch policy/result metadata at the pet repository boundary: source, stale state, fetched time and classified failures.
2. Classify HTTP authentication, permission, validation, parsing and transport errors before fallback. Apply D2: only genuine network failure permits stale cached results; never conceal 401/403 or arbitrary server/decoding failures. Define a finite freshness limit, including unknown timestamps from old caches; expired data requires explicit UI policy, not implicit success.
3. Preserve user-scoped storage and server-authoritative pruning. Do not re-upload local-only rows during reads.
4. Migrate list/detail/dashboard consumers together with explicit stale/offline presentation and retry behavior; verify logout/user switching cannot display another user's cache.

**Exit gate:** tests distinguish offline success-with-staleness from auth/domain failures; all migrated consumers handle metadata; online deletion remains deleted. **Rollback:** keep a compatibility adapter for the old repository API during migration, but do not restore catch-all fallback.

### 8. Give health entries one state owner

1. Choose and document one canonical health-entry store, normalized by ID with pet-indexed selectors or pet-keyed state. Define loading/error/freshness and session disposal; do not create a second mutable cache in the new controller.
2. Implement existing per-pet and global selectors as views of the canonical owner. Temporarily adapt old provider names so consumers can move without a flag-day rewrite.
3. Move issue-linking, occurrence completion and related refresh orchestration from widgets into a `CareScheduleController` or application command service. Keep form focus/selection and other ephemeral UI state local.
4. Apply server command results to canonical state, reconcile occurrences and expose refresh failure separately from command failure. Use request/session generations or equivalent guards so stale in-flight reads cannot overwrite newer mutations or a different user's state. Account for out-of-order reads, duplicate taps, route disposal, deletion and user switching; display per-pet loading/error state without mistaking a partially loaded store for a complete list.
5. Migrate issue linking, profile surfaces, care dashboard and occurrence widgets; remove independent fetch paths only after all consumers and test overrides have moved.

**Exit gate:** each mutation is visible across all selectors without manual widget invalidation; a committed mutation followed by failed refresh remains successful with explicit stale/retry state; repository/controller/widget tests cover each layer. **Rollback:** switch consumers through compatibility selectors, not dual writes to independent stores.

### 9. Publish public APIs and remove dependency cycles deliberately

1. For each component in the catalog, list owned models/state, exported queries/commands/UI entrypoints and allowed dependencies. Create narrow entrypoints without automatically exporting data implementations.
2. Add an import checker with a baseline of existing violation identities; block new deep imports and new cyclic dependencies, then ratchet the baseline down. Allow Experience and specifically named core composition entrypoints to consume feature public APIs; no blanket exemption for all `core` files and no domain-to-Experience-screen imports.
3. Start with taxonomy/value types, then pet/health contracts, then experience composition. Replace imports of another feature's screen/widget internals with a public model/callback or lift shared composition into the shell.
4. Decompose the 12-feature strongly connected component edge by edge after C, using the measured graph to choose cuts. Prioritize the forbidden pet-profile-to-Experience presentation direction; the 51 directives on `experience → pet_profile` include legitimate composition and are not all defects. Keep domain logic with its owner; “move to core” is not a general cycle remedy.
5. Apply the same ownership rule to server services/query modules: routes translate HTTP, application services orchestrate, and persistence accepts the transaction client. Keep simple CRUD direct where no use-case abstraction helps.

**Exit gate:** each active substantial feature has a documented public surface; no cross-feature private/data imports remain without explicit expiring exceptions; the target feature graph is acyclic. Track intermediate decreases rather than claiming success from a barrel-file count. **Rollback:** temporary forwarding exports preserve consumers while reverting a move; remove them only after usage checks.

### 10. Complete ports and central transport boundaries

1. Introduce `AuthRepository`/`SessionStore` at actual test/volatility seams while keeping the current AuthNotifier state machine and Riverpod 2.
2. Move health document upload/removal behind `HealthDocumentsRepository`; consolidate equivalent remote datasource providers and use the injected authenticated HTTP client as the token/refresh authority.
3. Migrate backend auth parsing to the existing principal/middleware boundary route by route, preserving capability checks and intended 401/403/404 distinctions.
4. Centralize Express 4-compatible async error translation; keep redaction and request correlation. Do not introduce an Express upgrade into this refactor.

**Exit gate:** auth refresh single-flight/replay, logout/session restoration and attachment create/delete/error tests pass; presentation no longer imports concrete transport adapters; authorization matrices are unchanged except documented fixes. **Rollback:** retain adapters for old construction points until callers migrate; do not introduce parallel token owners.

### 11. Make standards measurable and blocking

1. Publish exact eligible source sets for size, lint, coverage and BDD traceability using the same frozen/generated policy as the baseline.
2. Include missing eligible source files in coverage denominators instead of ignoring absent LCOV entries. Reconcile the documented 65% versus implemented 70% Flutter threshold; establish backend domain/changed-file ratchets from measured results rather than inventing a passing percentage.
3. Expand lint and size checks to active server libraries/services and classify Flutter screens/widgets separately. Apply D7: `server/lib` starts report-only; publish grandfathered entries and baseline offenders before ratcheting new/changed violations. Keep physical versus heuristic source lines distinct; adopt reviewed exceptions rather than mechanical splitting.
4. Separate BDD title mapping from executed tests, skeleton/orphan quality and assertion coverage. Respect existing active/frozen E2E classification and the separate navigation-check work.
5. Wire docs checks and boundary checks into the declared blocking CI gate; verify external branch protection separately when access is authorized. Add fixtures proving each checker fails on a deliberate violation.

**Exit gate:** missing files cannot improve coverage, new boundary violations fail CI, threshold documentation matches commands, and every intentional scoped skip is visible. **Rollback:** repair noisy checks using explicit baseline exceptions with expiry, not blanket disabling of enforcement.

### 12. Finish cohesive extractions and verify the target

1. Extract remaining large modules only along meaningful responsibilities: occurrence use cases/DTO mapping, planned-absence commands/queries, invite orchestration versus persistence, pet CRUD/lifecycle and health CRUD/documents.
2. For Flutter hotspots, extract independent visual subcomponents with explicit data/callback inputs; keep state ownership in controllers. Avoid wrappers that merely relocate lines.
3. Complete component READMEs using Appendix C and ADRs for transaction ownership, canonical health state and retained-data compatibility. Link public contracts and tests from the architecture index.
4. Run the supported Flutter analyzer/tests, backend unit/integration tests, OpenAPI/consumer contract checks, active E2E journeys and docs/boundary gates against the same revision. Recompute sizes/graph and publish before/after comparisons with identical exclusions.
5. Perform a final review of deletion, completion, sharing, login/logout and offline recovery. Verify operational visibility for pending cleanup/effects and document recovery procedures.

**Final acceptance:** all P1 findings have passing failure-path tests and resolved or explicitly approved contracts; required transactions use one client; committed responses are stable; canonical client ownership is enforced; active feature dependencies meet the approved acyclic model; retained-data privacy is preserved; all substantial component contracts and CI universes are documented. Remaining P2/P3 exceptions require an owner, reason and review date. This review itself does not certify any of those future gates as passing.

## Independent peer review (2026-09-22)

Decisions and sequencing in this historical peer review are superseded by Accepted decisions and revised delivery sequence above.

**Reviewer:** Cursor Cloud agent (independent validation against `main` at `818c1d6`, spot-checking P1 claims from the reviewed baseline `a8c7db1`).

**Overall verdict:** **Accept the report with minor sequencing and scoping refinements.** The diagnosis is accurate, evidence-backed, and appropriately conservative about what was and was not proven. The retain-monolith / fix-contracts recommendation matches repository reality and existing governance (`modularity.md`, frozen-domain policy, atomic-PR norms). The 12-package execution plan is sound but should be treated as a **program backlog**, not a single initiative — several packages are already independently mergeable.

### Claim validation (spot-checked on current `main`)

| Finding | Validation | Notes |
|---|---|---|
| A01 — `deleteAllPetData` uses `pool.query('BEGIN')` | **Confirmed** | `server/lib/petDataLifecycle.js:86-127` — each statement may use a different pool connection; audit is `logAuditEventSafe` (non-transactional). |
| A02 — post-commit work can yield 5xx after commit | **Confirmed pattern** | Weight completion and share-invite flows match the described commit-then-side-effect ordering; characterization tests are still missing. |
| A03 — frozen boundary checker narrower than manifest | **Confirmed** | `scripts/check_frozen_domain_boundaries.sh` hard-codes a Flutter allowlist omitting `pet_care`, `care_intelligence`, `care_taxonomy`, `pet_tags`; server scan is top-level `server/routes/*.js` only. |
| A04 — 12-feature strongly connected import graph | **Plausible; not re-run** | Methodology in Appendix D is reproducible; treat SCC as a **planning graph**, not a runtime dependency graph. |
| A05 — dual health-entry authorities | **Confirmed** | `petHealthEntriesProvider` (independent fetch) coexists with `petHealthEntriesByIdProvider` (global-derived); issue-link flow invalidates only the independent path (`health_issue_linkage_flow.dart:121,156`). |
| A06 — pet cache masks auth/network failures | **Confirmed** | `PetRepositoryImpl.getAllPets` catches all remote errors and returns local cache without stale/auth metadata (`pet_repository_impl.dart:76-85`). |
| A08 — passed-away DTO vs persistence split | **Confirmed** | `lifecycleRouter.js` returns `passed_away: true` for notification-only POST; persistence is via separate PUT on `coreRouter`. |
| A03 server — org transfer routes always registered | **Confirmed** | `server/routes/pets/index.js:25-26` mounts `transferRouter` and `familyEventsRouter` without frozen gate. |

No material disagreement with P1 integrity findings. The report correctly separates **confirmed implementation defects** from **inferred production impact** (none claimed).

### Strengths of this review

1. **Right default architecture.** Keeps Riverpod 2, Express 4, and the modular monolith; avoids microservices, CQRS, and universal repository layers — aligned with `agent-core` and `atomic-pr` policy.
2. **Evidence discipline.** Labels (confirmed / risk / recommendation), explicit exclusions, reproducible metrics script, and honest limits on static analysis.
3. **Actionable packaging.** Twelve numbered packages with exit gates, rollback notes, and dependency ordering map cleanly to atomic PRs.
4. **Governance gap analysis is valuable.** The 65% vs 70% Flutter coverage drift, LCOV absence loophole, and BDD title-mapping vs execution distinction are concrete CI improvements often missed in architecture reviews.
5. **Component catalog + README template.** Appendix C template is immediately adoptable; bridges the gap between folder structure and enforceable contracts.

### Gaps, refinements, and disagreements

1. **Experience layer is under-specified in cycle-breaking.** The 12-feature SCC is real, but `experience` is intentionally a **composition shell** (`docs/architecture/index.md` maps Pet Care UI to `features/experience/`). Package 9 should name an explicit rule: *domain features may not import `experience` presentation internals; `experience` may import feature public APIs only.* Breaking `pet_profile ↔ experience` edges (51 directives) is the highest-leverage cut — not symmetric “move to core.”
2. **Outbox scope should stay minimal.** Package 4 correctly limits outbox to **legally/operationally required** durable effects. Do not outbox cache refresh, activity telemetry, or display-name lookups — use invalidation + reconciliation metadata instead. Add an explicit **effect classification table** (required-durable / best-effort / projection) before Package 4 implementation.
3. **Package 2 vs Package 3 ordering.** Boundary gating (unregister org-transfer when frozen) is a **small, independent PR** that reduces product-risk surface immediately. Recommend running Package 2’s route-registration gate **in parallel with** Package 1 characterization tests, not strictly after them.
4. **Pet cache policy needs a product decision, not only engineering.** Package 7 requires choosing offline UX: read-only stale list vs empty state vs banner-with-retry. Engineering can implement any policy; product should pick default behavior for 401/403 (always fail loud) vs transient network (stale OK with metadata).
5. **Lifecycle contract (Package 6) needs a product call.** Three viable options: (a) rename POST to notification-only DTO, (b) consolidate into one transactional command, (c) deprecate POST and document PUT-only for installed clients. The report lists these but does not recommend one — **decision required before implementation** (see table below).
6. **Metrics script in-repo.** Added as `scripts/architecture/architecture-metrics.py` (see Appendix D reproduce command). Wire into CI report-only mode so graph/size regressions are diffable on PRs.
7. **Baseline drift.** Reviewed commit `a8c7db1` ≠ current `main` (`818c1d6` at peer review). Re-run Appendix D metrics on merge target before starting Package 11 ratchets; P1 code findings still hold on spot-check.

### Decisions required (owner: Engineering + Product/Privacy as noted)

| # | Decision | Options | Recommendation | Blocks |
|---|---|---|---|---|
| D1 | Passed-away API semantics | Notification-only POST vs single transactional command vs deprecate POST | **(a) Notification-only** with renamed DTO (`notification_sent`, not `passed_away: true`) unless mobile clients already persist on POST response | Package 6 |
| D2 | Offline pet list behavior | Stale cache + banner vs fail vs hybrid by error class | **Hybrid:** 401/403 always surface auth UI; network/5xx may return stale with `isStale` metadata | Package 7 |
| D3 | Account erasure response model | Synchronous completion claim vs `202 Accepted` + status polling | **`202 Accepted` + durable job** given PostHog/filesystem steps; privacy owner signs off | Package 5 |
| D4 | Outbox / job infrastructure | Reuse existing patterns vs new `cleanup_jobs` table + worker | **New minimal jobs table** for file erasure and required notifications only; no generic event bus | Packages 4–5 |
| D5 | Feature graph target | Full DAG vs allowlisted composition edges | **DAG with explicit allowlist** for `experience → *` and `core → *`; block all other cross-feature presentation imports | Package 9 |
| D6 | CI ratchet aggressiveness | Big-bang vs baseline+block-new | **Baseline manifest of existing violations + block new** (report’s Package 9/11 approach) | Package 11 |
| D7 | `server/lib` in size gate | Include immediately vs phased | **Phased:** add `server/lib` to size scan report-only first, then ratchet after top offenders identified | Package 11 |

### Recommended execution adjustments

Relative to the report’s package table, prefer this **first three sprints** (each = one or more atomic PRs):

| Sprint | Packages | Rationale |
|---|---|---|
| **Sprint A — Protect & characterize** | 1 (+ parallel 2 route gate) | Add failing characterization tests; gate org-transfer/family-events registration when frozen off; no behavior change beyond boundary compliance. |
| **Sprint B — Backend integrity** | 3 → 4 → 6 | Transaction runner + pet deletion fix; stable command results for weight/share; lifecycle DTO decision (D1). Highest data-integrity ROI. |
| **Sprint C — Client authority** | 7 → 8 (design during B) | Pet cache policy (D2); canonical health store cutover after command-result contract from B is stable. |

Defer Package 9 (full public API / cycle break) until Sprint C proves the **canonical state + command controller** pattern on health and pets — otherwise risk creating barrel files that re-export the same cycles.

Package 5 (account erasure) can run parallel to Sprint B once D3/D4 are decided; it is privacy-critical but touches fewer active UI surfaces than health state.

### Additional risks not emphasized in the report

1. **Installed native clients.** Any DTO or endpoint change (lifecycle, pet cache metadata, erasure status) needs an **installed-client compatibility matrix** before merge — the report mentions this but should be a **hard gate** on Packages 4–7.
2. **Dual API mount (`/api` and `/backend/api`).** Contract tests must continue to cover both prefixes when changing response shapes.
3. **Foster/org fields on active pet DTOs.** `PetRepositoryImpl` still merges `isFoster`, `organizationId`, etc. from remote responses. Even with route gating, **DTO semantics** may confuse Pet Care UX — track as a follow-up under Package 2 compatibility adapter work, not a silent cleanup.
4. **Grandfathered file-size allowlist.** Several hotspot files are likely allowlisted; Package 11 should publish allowlist entries alongside size metrics to avoid false confidence.

### Peer review conclusion

Adopt this document as the **architecture program charter** for Pet Care hardening. Merge to `main` once decisions D1–D4 are recorded. Do **not** batch Packages 1–12 into one integration effort — the report’s own atomic-PR and rollback guidance is correct; execution should honor it.

**Suggested status transition:** `proposed` → `accepted` once decisions D1–D4 are recorded (ADR or short addendum to this file).

## Verification and limitations

The report uses static evidence, not a new test-pass certification. Production behavior and external branch-protection settings were not queried. Function spans are heuristic; no AST-derived cyclomatic complexity or reliable change-frequency ranking is claimed. Static imports miss dynamic runtime edges. The conservative metrics exclusion list intentionally omits frozen-family internals even when reachable; their reachability is discussed only as an active boundary issue. Review depth and measurement exclusions are documented in the appendices.

The earlier navigation-test follow-up is separate work; do not duplicate it or count frozen UI expectations as active architectural failures without reclassifying that suite against the freeze contract.

---
## Appendix A — Frontend evidence and flow traces

## Scope
Read-only review of active Flutter + supporting Node API architecture. I excluded `features/organization`, `features/fostering_session`, organization/foster/custody routes/tests, and the two fostering presentation surfaces explicitly listed for removal (`docs/engineering/frozen-domains/manifest.json:4-20,32-43`). I did not run the app or tests.

## Architecture observed
- The documented target is feature-first Flutter with `presentation/controllers|screens|widgets`, `domain`, and `data`; controllers own validation/async orchestration (`docs/architecture/modularity.md:58-73`). Node routes should compose domain routers with business logic in shared libs (`docs/architecture/modularity.md:39-54`).
- Active Flutter domains include auth, pet profile, health/weight tracking, care intelligence/taxonomy, Pet Care/experience, notifications, sharing, tags, vets, subscription, help/about. The strongest clean-layer examples are pet profile and health tracking: domain repository ports (`pet_repository.dart:3-35`; `health_repository.dart:5-80`), data adapters (`pet_repository_impl.dart:10-16`; `health_repository_impl.dart:8-15`), and Riverpod composition roots (`pet_providers.dart:20-63`; `health_providers.dart:31-87`).
- Cross-cutting composition is in core: API origin (`api_base_url_provider.dart:4-10`), retrying authenticated HTTP (`auth_http_client.dart:20-58`), router (`app_router.dart:87-138`), and server dual mounts (`server/bin/server.js:102-144`).
- Node route composition is good: auth separates session/profile/password routers (`server/routes/auth/index.js:4-21`); pets composes focused routers (`server/routes/pets/index.js:20-37`); occurrence routes delegate scheduling behavior to `server/lib/care/schedule/*` (`occurrencesRouter.js:6-23,127-159`).

## Two traced active flows
### 1. Sign in
1. `LoginScreen._submit` validates, invokes `authProvider.notifier.login`, then navigates to `/` (`login_screen.dart:31-45`).
2. `AuthNotifier.login` sets loading state, calls the concrete service, persists tokens, and publishes user/token state (`auth_providers.dart:157-173,341-355`).
3. `AuthService.login` POSTs `/api/auth/login` and maps the JSON (`auth_service.dart:124-139`); web base URL is `/backend`, producing `/backend/api/auth/login` (`api_base_url_provider.dart:4-9`).
4. Server validates credentials, issues the token pair, sets the refresh cookie, and audits success/failure (`server/routes/auth/sessionRouter.js:72-118`).
5. Router listens only for logged-in transitions and redirects `/` to `/app/resolve` (`app_router.dart:47-64,87-93,107-138`).

Strengths: single-flight refresh and replay are explicit (`auth_providers.dart:306-339`; `auth_http_client.dart:41-57`); token storage is platform-specific—HttpOnly-cookie sentinel on web and secure storage on mobile (`token_store.dart:53-104,133-205`). Refresh behavior has focused tests (`auth_refresh_test.dart:21-127`).

### 2. Complete a care occurrence
1. UI loads open occurrences through `entryOccurrencesProvider` (`occurrence_providers.dart:7-11`) and selects stack/single completion (`occurrence_care_actions.dart:20-74`).
2. `persistCompletion` calls `HealthRepository.completeOccurrence`, then manually invalidates occurrence state and refreshes the global health list (`occurrence_care_actions.dart:76-101`).
3. Repository maps the domain call to the remote adapter (`health_repository_impl.dart:94-109`), which POSTs the calendar-day payload (`health_occurrence_remote_datasource.dart:48-77`).
4. Server authorizes management, rejects weight rhythms on the generic path, optionally skips earlier misses, completes through the scheduling service, audits activity, and returns occurrence plus `next_due_date` (`occurrencesRouter.js:93-163`).

Strengths: domain port isolates HTTP; calendar dates are serialized intentionally; server owns scheduling authority and authorization. UI failure is surfaced (`occurrence_care_actions.dart:119-147`).

## Prioritized findings
### P1 — Pet cache failure semantics conflict with server authority
`PetRepositoryImpl.getAllPets` correctly documents server authority and prunes local-only records (`pet_repository_impl.dart:70-75`), and tests assert that contract (`pet_repository_impl_test.dart:191-228`). However, every remote exception—including authorization/session failures—is converted into successful local-cache data (`pet_repository_impl.dart:18-85`). That makes freshness and authority unknowable to callers and can display stale records rather than an explicit failure. Local storage is sensibly user-scoped (`pet_local_datasource.dart:29-55`), but that does not resolve stale/error semantics.

Target:
```dart
abstract interface class PetProfilesRepository {
  Future<PetSnapshot> list({required PetFetchPolicy policy});
}
class PetSnapshot { List<Pet> pets; DataSource source; bool isStale; DateTime fetchedAt; }
```
Never fall back on 401/403/validation errors; allow offline fallback only through an explicit policy and return stale metadata.

### P1 — Health entries have two competing Riverpod authorities
The global `AsyncNotifier` is mutation-refreshed (`health_providers.dart:89-160`), while `petHealthEntriesProvider` independently fetches per pet and `petHealthEntriesByIdProvider` derives from the global list (`health_providers.dart:184-199`). Both are used. For example, issue linking invalidates only the independent provider (`health_issue_linkage_flow.dart:117-156`), while several profile surfaces watch the global-derived provider. This can produce divergent views after mutation.

Target: one canonical `HealthEntriesStore` keyed by pet or normalized by entry ID; all selectors derive from it. Expose commands on its notifier and centralize invalidation there.

### P1 — Occurrence application orchestration lives in widgets and is manually non-atomic
The widget directly calls repositories and coordinates two refreshes (`occurrence_care_actions.dart:76-108`), contrary to the controller-orchestration standard. Other occurrence widgets also do direct repository calls. A successful server mutation followed by a failed refresh leaves opaque state. Current datasource tests cover GET-open (`health_remote_datasource_test.dart:183-204`), but the reviewed repository suite has no occurrence command tests (`health_repository_impl_test.dart:31-142`), and no test exercises completion + both cache updates.

Target:
```dart
abstract interface class CompleteCareOccurrence {
  Future<OccurrenceCompletion> call(CompleteOccurrenceCommand command);
}
class CareScheduleController extends AsyncNotifier<CareScheduleState> {
  Future<void> complete(CompleteOccurrenceCommand command);
}
```
The controller should update/invalidate canonical entries and occurrences as one application operation.

### P2 — Auth lacks a domain boundary
Presentation constructs and depends directly on `AuthService` (`auth_providers.dart:7-16,61-67`); that service combines wire DTOs, user model, transport, and endpoint logic (`auth_service.dart:10-98,124-183`). Injection of `http.Client` makes it testable (`auth_service.dart:79-85`), but auth behavior cannot be swapped without presentation changes.

Target ports: `AuthRepository.signIn/restoreSession/refresh/signOut`, `SessionStore`, and domain `AuthenticatedSession`; keep HTTP DTO parsing in `AuthRemoteDataSource`. Preserve `AuthNotifier` as the presentation state machine.

### P2 — Health transport is duplicated and leaks into presentation
Two providers build equivalent mutable-token datasource instances (`health_providers.dart:31-51`). Photo controllers import and call the concrete datasource directly (`health_entry_form_controller_photos.dart:1-5,41-85`) while normal entry operations use the repository. This weakens dependency direction and doubles override/setup points.

Target: extend a domain-facing `HealthDocumentsRepository`; retain one remote datasource provider behind repositories. Authentication should come solely from the injected `AuthHttpClient`, not both mutable `authToken` state and the client (`health_remote_datasource.dart:95-116`).

## Phased recommendation
1. **Characterize first:** add tests for 401/403 vs offline pet fetch; occurrence POST mapping; completion success with canonical state update; issue-link mutation visibility across all selectors.
2. **Unify state:** replace the two health-entry providers with one normalized store and selectors; move occurrence commands from widgets into a controller.
3. **Clarify data authority:** introduce explicit cache policy/result metadata; prohibit silent cache fallback for auth/domain errors.
4. **Harden boundaries:** add auth repository/session interfaces and health-document repository; consolidate duplicate datasource providers.
5. **Incremental cleanup:** preserve current domain ports and thin Node composition; migrate one flow at a time under existing tests rather than broad rewrites.

Overall: dependency direction in the sampled pet/health domain and data layers is sound, server authority and authorization are generally strong, and Riverpod is used as a composition/test seam. The main architectural risk is not missing layers but multiple state/cache authorities and presentation-owned orchestration that bypasses those layers.

## Appendix B — Backend evidence and flow traces

## Read-only Node/Express architecture review

**Baseline/scope:** commit `a8c7db1be2e493f10623e6b9a37fced0b7a31d0c`; Node/Express/PostgreSQL. Reviewed active backend plus active→frozen seams only. Excluded internals under manifest roots `server/routes/organizations`, `fosterPlacements.js`, `custodyTransfers.js` (`docs/engineering/frozen-domains/manifest.json:8-20`). No edits/tests/runtime checks.

### Current architecture map
- **Composition/HTTP:** `server/bin/server.js:58-76` constructs app/pool and cross-cutting middleware; `:102-144` mounts active APIs under both `/api` and `/backend/api`, while frozen routers are feature-gated at `:110-114,133-137`.
- **Route composers:** auth (`server/routes/auth/index.js:9-21`), pets (`server/routes/pets/index.js:20-37`), health (`server/routes/healthEntries/index.js:10-20`), care context (`server/routes/careContext/index.js:8-18`), sharing (`server/routes/sharing.js:17-23`). This substantially follows the prescribed composer/subrouter standard (`docs/architecture/modularity.md:39-55`).
- **Application/domain logic:** `server/lib/care/**`, `server/services/sharing/**`, lifecycle/access/capability libraries. SQL is split inconsistently between services, query modules (`server/db/sharing/**`), route handlers, and libs.
- **Data ownership:** auth owns users/password reset/refresh sessions (`db/schema/canonical.sql:727-756`); pet profile/access/sharing owns pets, `pet_access`, share invites/links/tags/timeline (`:572-680`); health/schedule owns entries/issues/occurrences/doc metadata (`:319-409`); notifications `:410-428`; away planning `:682-704`; weight owns observations `:772-784`; vets `:758-770`. Retained org/foster rows remain shared only for privacy/export/access obligations.
- **Public API:** bearer JWT by default, documented dual prefixes (`docs/architecture/api-reference.md:15-27`); active families include auth, pets, health, weight, sharing, notifications, vets, planned absences, care projection/progression/intelligence. Critical Pet Care DTOs have OpenAPI + contract tests (`api-reference.md:23-27`).
- **Authorization:** JWT parsing is centralized (`server/lib/requireAuth.js:11-42`); capability vocabulary/policy is centralized (`server/lib/petCapabilityPolicy.js:11-26,38-66`), backed by owner/co-parent/carer/foster access rules (`server/lib/petAccess.js:51-179`).
- **Errors/observability:** production detail redaction (`server/config/security.js:8-27`), request IDs/access logs (`server/middleware/requestContext.js:11-32`), Pino audit records (`server/lib/audit.js:26-85`).
- **External adapters:** PostgreSQL Pool (`server/bin/server.js:40-55`), SMTP/Nodemailer (`server/config/mail.js:17-63`, `server/services/mailService.js:23-40`), filesystem upload/private-health storage, PostHog deletion.

### Two active flow traces
1. **Complete a weight-monitoring occurrence** — `POST /pets/:id/care-rhythms/:entryId/occurrences/:occurrenceId/complete-weight` is composed through `pets/index.js:28-31` → `careProgression/index.js:4-10`. Handler authenticates and maps HTTP (`completeWeightRouter.js:227-247`); service checks `WEIGHT_EDIT`, accessible pet, entry and occurrence, validates DTO, and handles replay (`:57-123`); weight insert + occurrence completion commit atomically (`:127-164`); cache/audit/activity/establishment run after commit (`:165-186`).
2. **Accept multi-pet share invite** — route authenticates/delegates (`sharing/inviteRoutes.js:67-80`); service starts transaction and row-locks invite (`shareInviteService.js:233-246`), verifies invitee/status (`:247-278`), upserts access and invite state (`:280-307`), resolves/creates notifications (`:309-325`), then commits (`:326-342`). Query ownership is cleanly isolated in `db/sharing/shareInviteQueries.js:100-143,172-204`.

### Strengths
- Frozen APIs default off and dormant org IDs are explicitly rejected (`server/lib/frozenDomains.js:1-24`). Active Jest config excludes frozen suites explicitly (`server/jest.config.active.cjs:3-29`).
- Capability names make sensitive policy reviewable; weight flow combines capability checks, validation, transaction, idempotency, explicit DTO mapping, and calendar-date normalization (`completeWeightRouter.js:46-51,65-123`; `weightOccurrenceCompletion.js:13-40,56-67`).
- Share acceptance uses `FOR UPDATE` (`shareInviteQueries.js:100-126`) and one transaction for access grants/status/notifications.
- Rate limiting is consistently attached at route-composer boundaries (`rateLimit.js:55-71`; auth composer `:9-15`).

## Prioritized findings

### P1 — CONFIRMED implementation defect: lifecycle “transaction” uses Pool, not one client
`deleteAllPetData` issues `BEGIN`, deletes, `COMMIT/ROLLBACK` through `pool.query` (`server/lib/petDataLifecycle.js:86-128`). A `pg.Pool` can dispatch each query to a different connection, so atomicity is not guaranteed. Audit is an independent, non-awaited safe call, not part of a guaranteed transaction. Files are deleted after commit on a best-effort basis; `files_removed` counts discovered URLs, not confirmed successful deletions (`:58-80,104-124`).
- **Target boundary/API:** one `TransactionRunner.run(pool, work)` that always acquires/releases `PoolClient`; `PetLifecycleService.deleteData({client,...})`; return DB deletion and file-purge outcome separately.
- **Migration:** first characterization tests with a pool that rotates clients; switch to central runner; enqueue or durably record file deletion after commit.
- **Verify:** injected failure mid-delete rolls all rows back on the same client; file failure is observable/retryable and never falsely reported removed.

### P1 — CONFIRMED defect path: post-commit failures can return 500 for successful writes
Weight completion commits at `completeWeightRouter.js:163`, then awaits cache refresh and establishment persistence at `:165,186`; either can reject and reach route 500 (`:245-247`) despite the committed observation. The catch also attempts rollback after commit (`:196-197`), which cannot undo it. Audit is a safe non-awaited call and activity is non-awaited; these are not the demonstrated awaited failure paths. Invite creation commits at `shareInviteService.js:158`, then inviter-name/pet-name reads and existing-user notification remain in the failure region (`:160-187`); retry can be rejected as an existing pending invite (`:106-125`). Email failure alone is correctly converted to delivery status (`:188-201`).
- **Target:** command result becomes authoritative immediately after commit. Put required durable effects behind a transactional outbox or equivalent durable job mechanism; handle optional cache/telemetry failures separately.
- **Migration:** classify mandatory vs best-effort effects; move required DB invariants inside the transaction, persist jobs only for required asynchronous effects, and use idempotent delivery keyed by occurrence/invite. Cache refresh can use invalidation/rebuild instead of an outbox.
- **Verify:** fault-inject every effect; API returns stable success for committed state; retries do not duplicate access/notifications.

### P1 — CONFIRMED active→frozen boundary leakage
Although frozen router mounting is gated, active pets always register `transferRouter` and `familyEventsRouter` (`pets/index.js:23-27`). `transferRouter` registers the authorized `/:id/transfer-to-org` command and imports `orgPetTransfer` (`transferRouter.js:3-30`). This is product/boundary noncompliance, not unauthenticated exposure. Active pet mapping also queries/returns foster placement semantics (`pets/shared.js:5-18,46-83`): retained-schema reads are explicitly permitted and are not themselves forbidden imports. Review their outward DTO semantics separately. The command/import boundary conflicts with the freeze rule that Shelter/Fostering are not active product (`pet-care-architecture.mdc:10-20`; freeze decision public API rule at `mvp-pivot-decisions.md:31-38`).
- **Target:** `PetCarePetRepository/DTO` owns only Pet Care concepts; compatibility adapter may read retained rows but must not expose organization/foster commands unless the frozen gate is enabled.
- **Migration:** gate org-transfer/family-event registration; isolate compatibility reads behind an interface; preserve old response fields only if installed-client analysis proves necessary, marking them deprecated.
- **Verify:** boundary fitness test enumerates active routes/import graph with frozen flag false; contract test proves no active org command is reachable.

### P2 — CONFIRMED API contract contradiction
`POST /pets/:id/passed-away` returns `passed_away: true` but only notifies; it never updates `pets.passed_away` (`lifecycleRouter.js:25-46`). The API reference calls lifecycle paths no-side-effect stubs at `api-reference.md:329-340`, but later says passed-away notifications are implemented and persistence occurs via a separate PUT (`:562-568`). Clients can reasonably interpret the command response as persisted state.
- **Target:** either an explicit `notification-preview/notify` API, or one transactional `markPetPassedAway` command that persists state and emits effects; publish one canonical OpenAPI contract.
- **Verify:** if retained as notification-only, its DTO claims notification delivery rather than persisted pet state and GET confirms no unintended mutation; if consolidated as a lifecycle command, GET reflects the persisted result. Preserve existing clients through an explicit compatibility/deprecation path. The detailed documentation already specifies separate PUT persistence; the finding is ambiguous naming/DTO and contradictory documentation, not failure to implement that documented PUT contract.

### P2 — CONFIRMED structural duplication; RISK of drift
Three transaction helpers exist: canonical `lib/db/withOptionalTransaction.js:1-29`, duplicate `pets/shared.js:102-122`, and nested duplicate shadowing its import in `transferRouter.js:7,40-60`. Auth is centralized but most routes repeatedly parse/check JWT rather than applying `requireAuth` middleware (`requireAuth.js:30-42`; examples `sharing.js:24-26,47-49,100-102`). No current bypass was confirmed, but policy/error drift risk is high.
- **Target:** one required transaction runner; router-level `requireAuth`; typed/request-scoped principal; capability middleware only where useful.
- **Verify:** static rule blocks duplicate BEGIN helpers and direct JWT parsing outside auth; auth matrix tests cover 401/403/404 behavior.

### P2 — CONFIRMED deletion orchestration; RISK of partial account deletion
Account deletion sequentially revokes sessions, purges files, calls PostHog, then deletes the user without DB transaction (`auth/profileRouter.js:194-215`). A later database failure can leave a live account with files/sessions already removed. Filesystem and PostHog failures are swallowed by their helpers, so those failures instead risk incomplete external erasure despite a successful response; they are not established throwing paths. Audit calls are fire-and-forget. These are implementation-confirmed risks; occurrence in production was not established.
- **Target:** `AccountErasureService`: transactional DB erasure/tombstone + durable external-erasure jobs; idempotent status API.
- **Verify:** fault injection at every step, rerun safety, retained frozen-table privacy/export coverage.

### P3 — RISK/maintainability
Large active files blur handler/use-case/query boundaries: `occurrencesRouter.js` 498 lines, `plannedAbsencesRouter.js` 449, `shareInviteService.js` 447, `pets/coreRouter.js` 389, `healthEntries/crudRouter.js` 376—above the repo’s “split when adding” threshold (`modularity.md:26-34`). Split incrementally by use case; verify with unchanged route/OpenAPI and characterization tests. Do not treat size alone as a defect.

## Appendix C — Governance evidence and documentation template

## Read-only architecture review

Scope excluded Shelter/Fostering implementation internals. No files changed and no workflows/tests were run.

### Highest-priority gaps

**P1 — Frozen-boundary enforcement is narrower than the declared manifest.** The manifest declares source, server, and test roots (`docs/engineering/frozen-domains/manifest.json:8-21`), but the boundary script hard-codes a Flutter directory allowlist and regex (`scripts/check_frozen_domain_boundaries.sh:6-22`) rather than consuming it. That allowlist omits active `pet_care`, `care_intelligence`, `care_taxonomy`, and `pet_tags`; server checking scans only top-level `server/routes/*.js` and one import spelling (`:41-50`), not active `server/lib`, nested routers, or `server/bin`. Thus the documented ACTIVE → FROZEN prohibition (`.agents/plans/frozen-domains-freeze-ab54.md:68-77`) is only partially enforced. Recommendation: generate both frozen roots and the active complement from the manifest, parse Dart/JS imports across all active production roots, and add fixture tests proving every declared root is blocked.

**P1 — Component APIs/layering are declared informally, not enforced.** Modularity prescribes Flutter `presentation/domain/data` and backend composition (`docs/architecture/modularity.md:39-69`), but there is no import/layer linter. Only 3 of 15 active Flutter features expose a top-level barrel. `pet_profile.dart` explicitly says external code should use its public API (`flutter_app/lib/features/pet_profile/pet_profile.dart:1-16`), while active code deep-imports other features’ presentation internals, e.g. `manage_events_collection_filter.dart:4` imports an Experience screen and `health_dashboard_care_filters.dart:5-6` imports Pet Profile widgets. Existing barrels also expose implementations: `health_tracking.dart:10-17` and `vet.dart:13-18` export data sources/repository implementations and UI. Recommendation: define allowed dependency direction and per-feature public entrypoints, then enforce with a Dart import-boundary checker plus tests.

**P1 — Size policy is materially narrower than its wording.** Docs describe hand-written code generally and screen/widget targets (`docs/architecture/modularity.md:26-35,58-73`), but the gate scans only `.dart/.js` under `flutter_app/lib` and `server/routes` (`scripts/check_file_size.js:24-30,65-88`). It does not cover `server/lib`, `server/bin`, scripts, tests, or E2E; it also cannot enforce the <300 screen target or 80-line private-widget rule. Current scanned active production files appear below 500 (largest observed active route: `server/routes/healthEntries/occurrencesRouter.js`, 498 lines), but many screens/widgets are 300–488 lines. Recommendation: classify paths by component type, include all hand-written production roots, enforce 500 globally and ratchet 300-line screens/80-line nested widgets.

**P1 — Coverage gates leave substantial blind spots and docs drift.** Flutter’s actual threshold is 70% (`flutter_app/scripts/merge_flutter_coverage.sh:7,49-50`), while CONTRIBUTING says 65% (`CONTRIBUTING.md:96`) and the gate contract says 65% (`docs/pipelines/ci-cd-gates.md:254`). The checker aggregates only domain files present in LCOV and silently skips missing/zero-line records (`flutter_app/scripts/check_domain_coverage.js:117-129`), with only a weak 20-file floor (`:147-151`). Jest thresholds cover only two policy files (`server/jest.config.cjs:6-18`); all other backend coverage is report-only (`.github/workflows/_reusable-test.yml:108-117`). Scoped PRs skip Flutter coverage whenever fewer than all shards run (`scripts/ci/ci-scope-lib.sh:424-433`), while the full audit is explicitly non-blocking (`.github/workflows/ci-full-audit.yml:1-3,164-188`). Recommendation: fail on every eligible domain source absent from LCOV, add per-domain thresholds, introduce a backend global/changed-file ratchet, and correct the 65/70 documentation.

**P1 — BDD “coverage” measures title mapping, not executed behavior.** The gate is 68% title matching (`e2e/scripts/check_bdd_coverage.js:34,132-148,198-203`), not assertion quality or execution. The quality scorecard’s skeleton/orphan metrics are informational in report-only use (`e2e/scripts/check_test_quality.js:66-99`; CI calls report-only at `_reusable-test.yml:51-55`). Recommendation: retain mapping as traceability, but separately gate orphan specs, skeleton tests, and publish executed scenario/pass-rate evidence.

**P1 — Documentation standards have a separate, potentially non-required gate.** Strict validation is well implemented (`scripts/validate_docs.sh:28-40,59-155`) and has a PR workflow (`.github/workflows/docs-validation.yml:3-11,36-40`), but the declared required checks are only CI gate and CodeQL (`docs/pipelines/ci-cd-gates.md:62-70`). Repository files cannot prove external branch settings. Recommendation: aggregate docs validation into `ci-gate` for docs-relevant changes or explicitly require its check; add architecture-doc consistency assertions for thresholds, shard names, and frozen manifest consumers.

**P2 — Dependency enforcement is solid for updates, uneven for policy.** Strengths: Dependabot covers server npm, E2E npm, and Flutter pub weekly (`.github/dependabot.yml:3-52`); CI uses `npm ci` and high-severity audit (`_reusable-test.yml:93-110,143-156`). Limits: ESLint covers only four policy paths (`eslint.config.js:4-9`; `scripts/validate_eslint.js:15-20`), and Flutter has unconstrained direct/dev dependencies (`flutter_app/pubspec.yaml:33,42-43`). Recommendation: expand lint via ratchet, document version-range policy, and add lockfile/fresh-resolution checks for Flutter.

### Strengths
- Clear freeze contract and explicit active/frozen CI posture (`freeze-verification-2026-09.md:14-22`).
- Umbrella CI gate enumerates all blocking jobs (`.github/workflows/ci.yml:179-218`) and validates scoped skips centrally (`_reusable-ci-gate.yml:60-90`).
- E2E manifest completeness is enforced with an explicit frozen allowlist (`e2e/scripts/validate-shard-manifest.mjs:18-51`); active shards are clearly enumerated (`shard-files.mjs:15-56`).
- Test sharding fails on empty shards and missing coverage artifacts (`flutter_app/scripts/run_tests_ci_shard.sh:62-77,121-133`; `_reusable-flutter-test-shard.yml:70-82`).
- Backend route READMEs provide useful responsibility maps and stable shim contracts (`server/routes/pets/README.md:5-19`; `server/routes/auth/README.md:5-21`).

### Recommended component documentation template

```md
---
title: <Component name>
owner: <team/person>
status: active | deprecated | frozen
component_id: <stable-id>
last_updated: YYYY-MM-DD
---

# Purpose
One responsibility; explicit non-goals.

## Location and entrypoint
- Production root:
- Public import/route:
- Composition root:

## Public API
| Symbol/endpoint | Inputs | Output | Errors | Stability |
|---|---|---|---|---|

## Layer contract
- May depend on:
- Must not depend on:
- Internal-only paths/symbols:
- State ownership and side effects:

## Data/wire contract
Models, serialization, validation, auth/permissions, compatibility rules.

## UI contract (if applicable)
States, accessibility semantics, responsive behavior, localization.

## Tests and gates
| Contract | Test path | Layer | Blocking gate |
|---|---|---|---|
Coverage target and accepted exclusions.

## Size/modularity budget
File/component limits, current exceptions, ratchet owner/date.

## Consumers and change protocol
Known consumers; breaking-change/deprecation process; migration notes.

## Operational notes
Observability, security/privacy, feature flags, rollback/failure behavior.
```

Adopt this first for cross-feature barrels, shared widgets/providers, backend route domains, and policy libraries; validate entrypoints and dependency declarations in CI.

## Appendix D — Reproducible inventory and measurements

# Architecture size metrics (refined)

Generated: 2026-09-22T13:56:50+00:00
Repository: /home/runner/workspace
Git commit: `a8c7db1be2e493f10623e6b9a37fced0b7a31d0c`

## Exact definitions

- **Review-scope production (headline):** active Flutter library after manifest/generated exclusions, including exclusion of `manifest.activeSurfacesToRemove`, plus the active server route-registration approximation from `server/bin/server.js`, minus the conservative Shelter-family server list below.
- **Active server route-registration approximation:** recursive literal relative `import`, `export ... from`, and `require()` traversal from `server/bin/server.js`, with the three frozen routers whose `app.use` mounts are gated by `frozenDomainsEnabled()` suppressed as review policy: organizations, fosterPlacements, custodyTransfers. Their imports are static and therefore still load under ESM; only registration is gated. This approximation is not actual runtime import reachability or closure. External and dynamic imports are ignored.
- **Server inventory complement:** tracked server source surviving path exclusions but not selected by that review-scope approximation. This is inventory, not a claim of dead or unloaded code: scripts, alternate entries, dynamic loads, and policy-suppressed imports can appear here.
- **Review-safe tests:** code under a `test`, `tests`, `__tests__`, or `e2e` path segment, or with a `.test`/`.spec` filename, after manifest test-root exclusions, `server/jest.config.active.cjs` ignore entries, and exact spec basenames exported by `e2e/scripts/frozen-e2e-specs.mjs`.
- **Shelter-family quality exclusion:** review-scope `server/lib` basenames beginning `org`, `adoption`, `foster`, or `fostering`, plus `custodyTransfers.js`, `sessionDetail.js`, and `deriveSessionStatus.js`. This conservative lexical list follows frozen Jest/domain naming and prevents frozen/mixed internals entering size ranking; it is not a statement that the modules cannot load.
- Inventory is exactly `git ls-files`; untracked files are absent. Source extensions: .cjs, .dart, .js, .jsx, .mjs, .sh, .sql, .ts, .tsx.
- **Approximate nonblank/noncomment lines are heuristic**, not cloc: blank lines, whole-line comments and block-comment spans are removed; strings and SQL dialects are not parsed.

## Headline

| Comparable scope                           | Files | Physical lines | Approx. nonblank noncomment |
| :----------------------------------------- | ----: | -------------: | --------------------------: |
| Review-scope production                    | 786   | 83,717         | 73,838                      |
|   active Flutter library                   | 629   | 66,491         | 59,510                      |
|   active server registration approximation | 157   | 17,226         | 14,328                      |
| Review-safe tests                          | 486   | 70,380         | 61,585                      |

## Classification audit

| Class                                                       | Files | Physical lines | Meaning                       |
| :---------------------------------------------------------- | ----: | -------------: | :---------------------------- |
| Server registration approximation (before family exclusion) | 167   | 19,863         | review-policy traversal       |
| Shelter-family removed from quality scope                   | 10    | 2,637          | conservative lexical list     |
| Server inventory complement                                 | 72    | 7,956          | not selected by approximation |
| Additional frozen CI tests removed                          | 38    | 6,137          | active Jest + frozen E2E sets |

### Shelter-family inventory excluded from quality totals/ranking

Every matching file is excluded: `review scope; removed` means it was subtracted from the registration approximation, while `inventory complement` means it did not enter that approximation. Neither label claims runtime loading behavior.

- `server/lib/adoptionJourneys.js` — inventory complement
- `server/lib/adoptionVisits.js` — inventory complement
- `server/lib/custodyTransfers.js` — review scope; removed
- `server/lib/deriveSessionStatus.js` — inventory complement
- `server/lib/email/templates/fosterInvitationNewUser.js` — inventory complement
- `server/lib/fosterAgreementWithdrawal.js` — inventory complement
- `server/lib/fosterCapacity.js` — inventory complement
- `server/lib/fosterCompliance.js` — inventory complement
- `server/lib/fosterInvite.js` — inventory complement
- `server/lib/fosterParentPresenter.js` — inventory complement
- `server/lib/fosterPlacements.js` — review scope; removed
- `server/lib/fosterProfiles.js` — inventory complement
- `server/lib/fosterRequests.js` — inventory complement
- `server/lib/fosterSessions.js` — inventory complement
- `server/lib/fosterVisibility.js` — inventory complement
- `server/lib/fosteringActivitySummary.js` — inventory complement
- `server/lib/orgConnections.js` — review scope; removed
- `server/lib/orgMemberPrivacy.js` — review scope; removed
- `server/lib/orgPeople.js` — review scope; removed
- `server/lib/orgPermissions.js` — review scope; removed
- `server/lib/orgPetShadow.js` — review scope; removed
- `server/lib/orgPetTransfer.js` — review scope; removed
- `server/lib/orgPetViewAccess.js` — review scope; removed
- `server/lib/orgRoles.js` — review scope; removed
- `server/lib/sessionDetail.js` — inventory complement

### Additional frozen CI tests removed

These are the non-manifest-root files selected by active Jest ignore entries or the frozen E2E set; manifest-root tests are already counted in path exclusions.

- `e2e/playwright/tests/adoption.spec.ts`
- `e2e/playwright/tests/experience.foster-portal.spec.ts`
- `e2e/playwright/tests/foster.onboarding.spec.ts`
- `e2e/playwright/tests/fostering.platform.spec.ts`
- `e2e/playwright/tests/fostering.session-detail.spec.ts`
- `e2e/playwright/tests/org.onboarding.spec.ts`
- `e2e/playwright/tests/org.timeline.spec.ts`
- `e2e/playwright/tests/organisation.admin-contacts.spec.ts`
- `e2e/playwright/tests/organisation.connections.spec.ts`
- `e2e/playwright/tests/organisation.customisations.spec.ts`
- `e2e/playwright/tests/organisation.dashboard.spec.ts`
- `e2e/playwright/tests/organisation.discovery.spec.ts`
- `e2e/playwright/tests/organisation.edit.spec.ts`
- `e2e/playwright/tests/organisation.management.spec.ts`
- `e2e/playwright/tests/organisation.member.privacy.spec.ts`
- `e2e/playwright/tests/organisation.permissions.spec.ts`
- `e2e/playwright/tests/organisation.pet-filters.spec.ts`
- `e2e/playwright/tests/organisation.pet.management.spec.ts`
- `e2e/playwright/tests/organisation.profile.spec.ts`
- `e2e/playwright/tests/organisation.redacted-pet.spec.ts`
- `e2e/playwright/tests/organisation.sessions.spec.ts`
- `server/test/adoptionJourneys.test.js`
- `server/test/adoptionVisits.test.js`
- `server/test/custodyTransfers.test.js`
- `server/test/externalFosterNotice.test.js`
- `server/test/fosterCapacity.test.js`
- `server/test/fosterPlacements.test.js`
- `server/test/fosteringActivitySummary.test.js`
- `server/test/orgConnections.test.js`
- `server/test/orgPeople.test.js`
- `server/test/orgPeopleRedaction.test.js`
- `server/test/orgPermissions.test.js`
- `server/test/orgPetTransfer.test.js`
- `server/test/orgRoles.test.js`
- `server/test/organizationsDiscover.test.js`
- `server/test/pets/orgMembership.test.js`
- `server/test/sessionDetail.test.js`
- `server/test/sessionLifecycle.test.js`

## Active Flutter library by feature/core

| Area                      | Files | Physical lines | Heuristic lines |
| :------------------------ | ----: | -------------: | --------------: |
| core/branding             | 1     | 85             | 54              |
| core/config               | 1     | 20             | 12              |
| core/network              | 1     | 83             | 57              |
| core/providers            | 6     | 143            | 114             |
| core/router               | 8     | 950            | 874             |
| core/services             | 4     | 321            | 276             |
| core/theme                | 4     | 559            | 469             |
| core/utils                | 5     | 342            | 271             |
| core/web                  | 6     | 182            | 127             |
| core/widgets              | 26    | 2,558          | 2,281           |
| feature/about             | 7     | 454            | 419             |
| feature/auth              | 27    | 4,358          | 4,039           |
| feature/care_intelligence | 18    | 1,133          | 1,005           |
| feature/care_taxonomy     | 7     | 401            | 369             |
| feature/experience        | 61    | 7,818          | 6,809           |
| feature/health_tracking   | 113   | 14,376         | 12,935          |
| feature/help              | 1     | 237            | 206             |
| feature/notifications     | 18    | 2,325          | 2,107           |
| feature/pet_care          | 59    | 5,924          | 5,330           |
| feature/pet_profile       | 175   | 16,187         | 14,601          |
| feature/pet_tags          | 11    | 779            | 694             |
| feature/sharing           | 31    | 3,585          | 3,269           |
| feature/subscription      | 4     | 722            | 651             |
| feature/vet               | 27    | 2,442          | 2,103           |
| feature/weight_tracking   | 7     | 396            | 341             |
| main.dart                 | 1     | 111            | 97              |

## Active server route-registration approximation by area

| Area       | Files | Physical lines | Heuristic lines |
| :--------- | ----: | -------------: | --------------: |
| bin        | 1     | 172            | 153             |
| config     | 10    | 430            | 280             |
| db         | 3     | 467            | 426             |
| lib        | 70    | 7,529          | 5,641           |
| middleware | 2     | 76             | 59              |
| routes     | 67    | 7,618          | 6,940           |
| services   | 4     | 934            | 829             |

## Review-safe tests

| Area        | Files | Physical lines | Heuristic lines |
| :---------- | ----: | -------------: | --------------: |
| .github     | 5     | 365            | 311             |
| e2e         | 83    | 15,301         | 12,689          |
| flutter_app | 252   | 32,101         | 28,225          |
| scripts     | 29    | 2,652          | 2,280           |
| server      | 117   | 19,961         | 18,080          |

## Biggest 15 review-scope production files

| File                                                                                                            | Physical lines | Heuristic lines |
| :-------------------------------------------------------------------------------------------------------------- | -------------: | --------------: |
| server/routes/healthEntries/occurrencesRouter.js                                                                | 498            | 478             |
| flutter_app/lib/features/auth/presentation/widgets/landing/landing_auth_forms.dart                              | 488            | 467             |
| flutter_app/lib/core/widgets/consent_banner.dart                                                                | 463            | 435             |
| flutter_app/lib/features/subscription/presentation/screens/paywall_screen.dart                                  | 457            | 435             |
| flutter_app/lib/features/health_tracking/data/datasources/health_remote_datasource.dart                         | 451            | 410             |
| server/routes/careContext/plannedAbsencesRouter.js                                                              | 449            | 392             |
| server/services/sharing/shareInviteService.js                                                                   | 447            | 399             |
| flutter_app/lib/features/pet_profile/presentation/screens/pet_form_screen.dart                                  | 441            | 406             |
| flutter_app/lib/features/notifications/presentation/widgets/notification_panel.dart                             | 437            | 398             |
| flutter_app/lib/features/experience/presentation/screens/pet_care/pet_care_due_events_screen.dart               | 421            | 342             |
| flutter_app/lib/core/router/app_router.dart                                                                     | 418            | 403             |
| flutter_app/lib/features/pet_profile/presentation/screens/widgets/manage_events_collection_filter.dart          | 411            | 372             |
| flutter_app/lib/features/experience/presentation/screens/pet_care/global_events_list.dart                       | 409            | 317             |
| flutter_app/lib/features/pet_profile/presentation/screens/pet_list_screen.dart                                  | 409            | 391             |
| flutter_app/lib/features/health_tracking/presentation/widgets/health_dashboard/health_dashboard_entry_list.dart | 408            | 375             |

## Function-length heuristic: top 8

This is deliberately narrow and approximate: only JS/TS/Dart functions whose complete signature and opening brace are on one line are candidates. Comments and simple quoted strings are stripped, then physical lines are counted until braces balance. Multiline signatures are missed; regex literals, interpolation, unusual syntax, or braces in complex strings can distort spans. Use only as a triage signal, never a quality gate.

| Function                   | File:line                                                                                            | Physical span |
| :------------------------- | :--------------------------------------------------------------------------------------------------- | ------------: |
| registerOccurrenceRoutes   | server/routes/healthEntries/occurrencesRouter.js:63                                                  | 386           |
| build                      | flutter_app/lib/features/pet_profile/presentation/screens/pet_list_screen.dart:58                    | 351           |
| registerCoreRoutes         | server/routes/pets/coreRouter.js:41                                                                  | 349           |
| registerCrudRoutes         | server/routes/healthEntries/crudRouter.js:29                                                         | 348           |
| registerFamilyEventsRoutes | server/routes/pets/familyEventsRouter.js:8                                                           | 271           |
| registerCompletionRoutes   | server/routes/healthEntries/completionRouter.js:17                                                   | 261           |
| build                      | flutter_app/lib/features/pet_profile/presentation/widgets/pet_detail/pet_detail_profile_card.dart:33 | 244           |
| build                      | flutter_app/lib/features/notifications/presentation/widgets/notification_tile.dart:33                | 225           |

## Cross-feature Flutter imports

Only literal Dart `import`, `export`, and `part` directives are scanned. Package paths resolve at `flutter_app/lib`; relative paths normalize from the importer. URI conditionals, interpolation, aliases and runtime references are ignored; self-feature edges are omitted.

Unique directed feature edges: **50**; matching directives: **466**.

| Edge                                | Importing files | Directives |
| :---------------------------------- | --------------: | ---------: |
| auth → about                        | 1               | 1          |
| auth → experience                   | 4               | 4          |
| care_intelligence → auth            | 1               | 1          |
| care_intelligence → health_tracking | 1               | 1          |
| care_intelligence → pet_care        | 4               | 5          |
| care_intelligence → pet_profile     | 4               | 5          |
| care_taxonomy → health_tracking     | 1               | 2          |
| care_taxonomy → pet_profile         | 3               | 3          |
| experience → auth                   | 4               | 5          |
| experience → health_tracking        | 8               | 19         |
| experience → notifications          | 2               | 2          |
| experience → pet_care               | 5               | 7          |
| experience → pet_profile            | 22              | 51         |
| experience → pet_tags               | 1               | 3          |
| experience → sharing                | 2               | 2          |
| experience → vet                    | 1               | 3          |
| health_tracking → auth              | 2               | 2          |
| health_tracking → care_taxonomy     | 13              | 25         |
| health_tracking → experience        | 2               | 4          |
| health_tracking → pet_care          | 2               | 3          |
| health_tracking → pet_profile       | 35              | 69         |
| health_tracking → weight_tracking   | 1               | 1          |
| notifications → auth                | 1               | 1          |
| notifications → pet_profile         | 6               | 10         |
| pet_care → auth                     | 2               | 2          |
| pet_care → care_intelligence        | 3               | 7          |
| pet_care → experience               | 4               | 8          |
| pet_care → health_tracking          | 4               | 7          |
| pet_care → pet_profile              | 10              | 13         |
| pet_profile → auth                  | 4               | 4          |
| pet_profile → care_intelligence     | 2               | 4          |
| pet_profile → care_taxonomy         | 5               | 6          |
| pet_profile → experience            | 17              | 29         |
| pet_profile → health_tracking       | 31              | 67         |
| pet_profile → notifications         | 4               | 4          |
| pet_profile → pet_care              | 12              | 18         |
| pet_profile → pet_tags              | 1               | 1          |
| pet_profile → sharing               | 7               | 7          |
| pet_profile → vet                   | 6               | 7          |
| pet_profile → weight_tracking       | 10              | 16         |
| pet_tags → auth                     | 1               | 1          |
| pet_tags → experience               | 1               | 2          |
| sharing → auth                      | 4               | 4          |
| sharing → experience                | 1               | 2          |
| sharing → pet_profile               | 12              | 15         |
| subscription → auth                 | 1               | 1          |
| vet → auth                          | 1               | 1          |
| vet → experience                    | 1               | 1          |
| vet → pet_profile                   | 6               | 9          |
| weight_tracking → auth              | 1               | 1          |

### Cycles

Strongly connected multi-feature components: **1**. Components mean mutual reachability, not every simple cycle.

- auth ↔ care_intelligence ↔ care_taxonomy ↔ experience ↔ health_tracking ↔ notifications ↔ pet_care ↔ pet_profile ↔ pet_tags ↔ sharing ↔ vet ↔ weight_tracking

## Exclusions

| Reason                             | Tracked files | Source files | Source physical lines |
| :--------------------------------- | ------------: | -----------: | --------------------: |
| frozen manifest roots              | 354           | 351          | 48,994                |
| manifest active surfaces to remove | 2             | 2            | 327                   |
| generated source                   | 3             | 3            | 24,721                |
| build/tool outputs                 | 0             | 0            | 0                     |
| dependency outputs                 | 0             | 0            | 0                     |
| design/media outputs               | 266           | 180          | 15,816                |

Tracked files total: **3,008**. Eligible source files after path exclusions: **1,678**. Files outside exact headline definitions remain inventory only. Frozen CI test removals are classification removals in addition to path exclusions and are reported above.

## Reproduce

```sh
python3 scripts/architecture/architecture-metrics.py \
  --repo "$(git rev-parse --show-toplevel)" \
  --output /tmp/architecture-metrics.md
```


## Appendix E — Measurement implementation

Canonical script: `scripts/architecture/architecture-metrics.py` (same content as below). Run the command in Appendix D from the repository root. The script writes only the requested output report. Measurements refer to the reviewed baseline, not future code.

```python
#!/usr/bin/env python3
"""Measure architecture size from Git-tracked files; writes Markdown to /tmp."""
from __future__ import annotations
import argparse, collections, datetime as dt, json, os, re, subprocess
from pathlib import Path, PurePosixPath

EXT={'.dart','.js','.mjs','.cjs','.ts','.tsx','.jsx','.sh','.sql'}
DESIGN=('artifacts/','attached_assets/','screenshots/','.canvas/')
BUILD=('build/','flutter_app/build/','.dart_tool/','coverage/','dist/','out/')
DEPS=('node_modules/','vendor/','.pub-cache/')
GEN_SUFFIX=('.g.dart','.freezed.dart','.mocks.dart','.gen.dart')
GEN_NAMES={'flutter_app/lib/l10n/app_localizations.dart'}
TEST_PARTS={'test','tests','__tests__','e2e'}

def git(root,*args): return subprocess.check_output(['git','-C',str(root),*args],text=True)
def under(p,roots): return any(p==r.rstrip('/') or p.startswith(r.rstrip('/')+'/') for r in roots)
def istest(p):
    return bool(set(PurePosixPath(p).parts)&TEST_PARTS) or bool(re.search(r'(?:^|[._-])(test|spec)\.[^.]+$',PurePosixPath(p).name.lower()))
def lines(path):
    """Physical and heuristic nonblank/noncomment line counts."""
    text=path.read_text(encoding='utf-8',errors='replace'); ls=text.splitlines(); n=0; block=False
    for raw in ls:
        s=raw.strip()
        if not s: continue
        while s:
            if block:
                j=s.find('*/')
                if j<0: s=''; break
                block=False; s=s[j+2:].strip(); continue
            if s.startswith('/*'): block=True; s=s[2:].strip(); continue
            if s.startswith('//') or s.startswith('#') or s.startswith('*'): s=''; break
            j=s.find('/*')
            if j>=0:
                if s[:j].strip(): n+=1
                block=True; s=s[j+2:].strip(); continue
            n+=1; break
    return len(ls),n
def table(head,rows,align=None):
    if not rows:return '_None._\n'
    rows=[[str(x) for x in r] for r in rows]; widths=[len(x) for x in head]
    for r in rows:
        for i,x in enumerate(r):widths[i]=max(widths[i],len(x))
    fmt=lambda r:'| '+' | '.join(str(x).ljust(widths[i]) for i,x in enumerate(r))+' |'
    sep=[]
    for i,w in enumerate(widths):
        a=align[i] if align else 'left'; sep.append((':' if a=='left' else '')+'-'*max(3,w-1)+(':' if a=='right' else ''))
    return '\n'.join([fmt(head),'| '+' | '.join(sep)+' |',*[fmt(r) for r in rows]])+'\n'
def grouped(paths,metric,key):
    g=collections.defaultdict(list)
    for p in paths:g[key(p)].append(p)
    return [(k,len(v),f'{sum(metric[p][0] for p in v):,}',f'{sum(metric[p][1] for p in v):,}') for k,v in sorted(g.items())]
def scc(graph):
    ix=0; stack=[]; on=set(); ids={}; low={}; out=[]
    def visit(v):
        nonlocal ix
        ids[v]=low[v]=ix;ix+=1;stack.append(v);on.add(v)
        for w in graph.get(v,()):
            if w not in ids:visit(w);low[v]=min(low[v],low[w])
            elif w in on:low[v]=min(low[v],ids[w])
        if low[v]==ids[v]:
            c=[]
            while True:
                w=stack.pop();on.remove(w);c.append(w)
                if w==v:break
            if len(c)>1:out.append(sorted(c))
    for v in sorted(graph):
        if v not in ids:visit(v)
    return sorted(out)

def server_review_scope(root, candidates, entry='server/bin/server.js'):
    """Approximate active route-registration dependencies; not runtime import closure."""
    candidates=set(candidates); seen=set(); todo=[entry]
    irx=re.compile(r"(?:\bimport\s+(?:[^'\"]*?\s+from\s+)?|\bexport\s+[^'\"]*?\s+from\s+|\brequire\s*\()\s*['\"]([^'\"]+)['\"]",re.M)
    gated={('../routes/organizations.js'),('../routes/fosterPlacements.js'),('../routes/custodyTransfers.js')}
    while todo:
        p=todo.pop()
        if p in seen or p not in candidates:continue
        seen.add(p); text=(root/p).read_text(encoding='utf-8',errors='replace')
        for spec in irx.findall(text):
            if p=='server/bin/server.js' and spec in gated:continue
            if not spec.startswith('.'):continue
            q=os.path.normpath(str(PurePosixPath(p).parent/spec)).replace('\\','/')
            choices=(q,q+'.js',q+'.mjs',q+'/index.js')
            target=next((x for x in choices if x in candidates),None)
            if target and target not in seen:todo.append(target)
    return sorted(seen)

def shelter_family_server(p):
    """Conservative quality-review exclusion, not a runtime claim."""
    if not p.startswith('server/lib/'):return False
    name=PurePosixPath(p).name
    return bool(re.match(r'^(org|adoption|foster|fostering)',name,re.I)) or name in {'custodyTransfers.js','sessionDetail.js','deriveSessionStatus.js'}

def function_spans(root, paths):
    """Single-line-signature brace-span heuristic for JS/Dart; deliberately narrow."""
    found=[]
    control=re.compile(r'^\s*(if|for|while|switch|catch|else|try|do)\b')
    sig=re.compile(r'^\s*(?:export\s+)?(?:async\s+)?(?:function\s+)?(?:[\w<>?,.\[\] ]+\s+)?([A-Za-z_$][\w$]*)\s*\([^;{}]*\)\s*(?:async\s*)?(?:=>\s*)?\{\s*$')
    for p in paths:
        if PurePosixPath(p).suffix not in {'.js','.mjs','.ts','.tsx','.dart'}:continue
        raw=(root/p).read_text(encoding='utf-8',errors='replace').splitlines()
        clean=[]; block=False
        for line in raw:
            x=line
            if block:
                j=x.find('*/')
                if j<0:clean.append('');continue
                x=x[j+2:];block=False
            x=re.sub(r'//.*','',x)
            while '/*' in x:
                a=x.find('/*');b=x.find('*/',a+2)
                if b<0:x=x[:a];block=True;break
                x=x[:a]+x[b+2:]
            x=re.sub(r"'(?:\\.|[^'\\])*'|\"(?:\\.|[^\"\\])*\"|`(?:\\.|[^`\\])*`",'""',x)
            clean.append(x)
        for i,line in enumerate(clean):
            m=sig.match(line)
            if not m or control.match(line):continue
            depth=0;started=False
            for j in range(i,len(clean)):
                depth+=clean[j].count('{')-clean[j].count('}')
                started=started or '{' in clean[j]
                if started and depth<=0:
                    found.append((j-i+1,p,i+1,m.group(1)));break
    return sorted(found,key=lambda x:(-x[0],x[1],x[2]))

def main():
    a=argparse.ArgumentParser();a.add_argument('--repo');a.add_argument('--output',default='/tmp/architecture-metrics.md');o=a.parse_args()
    root=Path(o.repo).resolve() if o.repo else Path(git(Path.cwd(),'rev-parse','--show-toplevel').strip())
    tracked=[p for p in git(root,'ls-files').splitlines() if p]
    manifest=json.loads((root/'docs/engineering/frozen-domains/manifest.json').read_text())
    frozen=manifest.get('sourceRoots',[])+manifest.get('serverRoots',[])+manifest.get('testRoots',[])
    active_surfaces=set(manifest.get('activeSurfacesToRemove',[]))
    excluded=collections.defaultdict(list); eligible=[]
    for p in tracked:
        if under(p,frozen):excluded['frozen manifest roots'].append(p)
        elif p in active_surfaces:excluded['manifest active surfaces to remove'].append(p)
        elif under(p,DESIGN):excluded['design/media outputs'].append(p)
        elif under(p,BUILD):excluded['build/tool outputs'].append(p)
        elif under(p,DEPS):excluded['dependency outputs'].append(p)
        elif p in GEN_NAMES or p.endswith(GEN_SUFFIX) or (p.startswith('flutter_app/lib/l10n/app_localizations_') and p.endswith('.dart')):excluded['generated source'].append(p)
        else:eligible.append(p)
    code=[p for p in eligible if PurePosixPath(p).suffix.lower() in EXT]
    excluded_code=[p for xs in excluded.values() for p in xs if PurePosixPath(p).suffix.lower() in EXT]
    metric={p:lines(root/p) for p in set(code+excluded_code)}
    flutter=[p for p in code if p.startswith('flutter_app/lib/')]
    server_inventory=[p for p in code if p.startswith('server/') and not istest(p)]
    server_scope=server_review_scope(root,server_inventory)
    server_complement=sorted(set(server_inventory)-set(server_scope))
    shelter_inventory=sorted(p for p in server_inventory if shelter_family_server(p))
    shelter_quality=sorted(set(server_scope)&set(shelter_inventory))
    shelter_complement=sorted(set(shelter_inventory)-set(server_scope))
    server_review=sorted(set(server_scope)-set(shelter_quality))
    all_tests=[p for p in code if istest(p)]
    jest_text=(root/'server/jest.config.active.cjs').read_text()
    frozen_jest={'server/'+x for x in re.findall(r"<rootDir>/(test/[^'\"]+)",jest_text)}
    e2e_text=(root/'e2e/scripts/frozen-e2e-specs.mjs').read_text()
    frozen_e2e_names=set(re.findall(r"['\"]([^'\"]+\.spec\.ts)['\"]",e2e_text))
    frozen_ci_tests=sorted(p for p in all_tests if p in frozen_jest or (p.startswith('e2e/') and PurePosixPath(p).name in frozen_e2e_names))
    tests=sorted(set(all_tests)-set(frozen_ci_tests))
    prod=sorted(set(flutter+server_review))
    def fg(p):
        x=PurePosixPath(p).parts
        if len(x)>=4 and x[2]=='features':return 'feature/'+x[3]
        if len(x)>=4 and x[2]=='core':return 'core/'+x[3]
        return x[2] if len(x)>2 else '(root)'
    def sg(p):
        x=PurePosixPath(p).parts;return x[1] if len(x)>2 else '(root/config)'
    def tg(p):
        for x in ('flutter_app','server','e2e'):
            if p.startswith(x+'/'):return x
        return p.split('/',1)[0]
    # Literal Dart directives only. Resolve package features and normalized relatives.
    rx=re.compile(r'^\s*(?:import|export|part)\s+[\'\"]([^\'\"]+)[\'\"]',re.M)
    ec=collections.Counter();ef=collections.defaultdict(set);graph=collections.defaultdict(set)
    for p in flutter:
        parts=PurePosixPath(p).parts
        if len(parts)<4 or parts[2]!='features':continue
        src=parts[3]
        for spec in rx.findall((root/p).read_text(encoding='utf-8',errors='replace')):
            target=None
            if spec.startswith('package:') and '/features/' in spec:target=spec.split('/features/',1)[1].split('/',1)[0]
            elif spec.startswith('.'):
                resolved=PurePosixPath(os.path.normpath(str(PurePosixPath(p).parent/spec)));rp=resolved.parts
                if len(rp)>=4 and rp[:3]==('flutter_app','lib','features'):target=rp[3]
            if target and target!=src:
                ec[src,target]+=1;ef[src,target].add(p);graph[src].add(target);graph.setdefault(target,set())
    cycles=scc(graph)
    pl=lambda ps:sum(metric[p][0] for p in ps);hl=lambda ps:sum(metric[p][1] for p in ps)
    commit=git(root,'rev-parse','HEAD').strip();stamp=dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat()
    fspans=function_spans(root,prod)[:8]
    out=['# Architecture size metrics (refined)','',f'Generated: {stamp}',f'Repository: {root}',f'Git commit: `{commit}`','',
      '## Exact definitions','',
      '- **Review-scope production (headline):** active Flutter library after manifest/generated exclusions, including exclusion of `manifest.activeSurfacesToRemove`, plus the active server route-registration approximation from `server/bin/server.js`, minus the conservative Shelter-family server list below.',
      '- **Active server route-registration approximation:** recursive literal relative `import`, `export ... from`, and `require()` traversal from `server/bin/server.js`, with the three frozen routers whose `app.use` mounts are gated by `frozenDomainsEnabled()` suppressed as review policy: organizations, fosterPlacements, custodyTransfers. Their imports are static and therefore still load under ESM; only registration is gated. This approximation is not actual runtime import reachability or closure. External and dynamic imports are ignored.',
      '- **Server inventory complement:** tracked server source surviving path exclusions but not selected by that review-scope approximation. This is inventory, not a claim of dead or unloaded code: scripts, alternate entries, dynamic loads, and policy-suppressed imports can appear here.',
      '- **Review-safe tests:** code under a `test`, `tests`, `__tests__`, or `e2e` path segment, or with a `.test`/`.spec` filename, after manifest test-root exclusions, `server/jest.config.active.cjs` ignore entries, and exact spec basenames exported by `e2e/scripts/frozen-e2e-specs.mjs`.',
      '- **Shelter-family quality exclusion:** review-scope `server/lib` basenames beginning `org`, `adoption`, `foster`, or `fostering`, plus `custodyTransfers.js`, `sessionDetail.js`, and `deriveSessionStatus.js`. This conservative lexical list follows frozen Jest/domain naming and prevents frozen/mixed internals entering size ranking; it is not a statement that the modules cannot load.',
      '- Inventory is exactly `git ls-files`; untracked files are absent. Source extensions: '+', '.join(sorted(EXT))+'.',
      '- **Approximate nonblank/noncomment lines are heuristic**, not cloc: blank lines, whole-line comments and block-comment spans are removed; strings and SQL dialects are not parsed.','',
      '## Headline','',table(['Comparable scope','Files','Physical lines','Approx. nonblank noncomment'],[
        ('Review-scope production',len(prod),f'{pl(prod):,}',f'{hl(prod):,}'),
        ('  active Flutter library',len(flutter),f'{pl(flutter):,}',f'{hl(flutter):,}'),
        ('  active server registration approximation',len(server_review),f'{pl(server_review):,}',f'{hl(server_review):,}'),
        ('Review-safe tests',len(tests),f'{pl(tests):,}',f'{hl(tests):,}')],['left','right','right','right']),
      '## Classification audit','',table(['Class','Files','Physical lines','Meaning'],[
        ('Server registration approximation (before family exclusion)',len(server_scope),f'{pl(server_scope):,}','review-policy traversal'),
        ('Shelter-family removed from quality scope',len(shelter_quality),f'{pl(shelter_quality):,}','conservative lexical list'),
        ('Server inventory complement',len(server_complement),f'{pl(server_complement):,}','not selected by approximation'),
        ('Additional frozen CI tests removed',len(frozen_ci_tests),f'{pl(frozen_ci_tests):,}','active Jest + frozen E2E sets')],['left','right','right','left']),
      '### Shelter-family inventory excluded from quality totals/ranking','', 'Every matching file is excluded: `review scope; removed` means it was subtracted from the registration approximation, while `inventory complement` means it did not enter that approximation. Neither label claims runtime loading behavior.','', '\n'.join('- `'+p+'` — '+('review scope; removed' if p in shelter_quality else 'inventory complement') for p in shelter_inventory) if shelter_inventory else '_None._','',
      '### Additional frozen CI tests removed','', 'These are the non-manifest-root files selected by active Jest ignore entries or the frozen E2E set; manifest-root tests are already counted in path exclusions.','', '\n'.join('- `'+p+'`' for p in frozen_ci_tests) if frozen_ci_tests else '_None._','',
      '## Active Flutter library by feature/core','',table(['Area','Files','Physical lines','Heuristic lines'],grouped(flutter,metric,fg),['left','right','right','right']),
      '## Active server route-registration approximation by area','',table(['Area','Files','Physical lines','Heuristic lines'],grouped(server_review,metric,sg),['left','right','right','right']),
      '## Review-safe tests','',table(['Area','Files','Physical lines','Heuristic lines'],grouped(tests,metric,tg),['left','right','right','right'])]
    biggest=sorted(prod,key=lambda p:(-metric[p][0],p))[:15]
    out+=['## Biggest 15 review-scope production files','',table(['File','Physical lines','Heuristic lines'],[(p,f'{metric[p][0]:,}',f'{metric[p][1]:,}') for p in biggest],['left','right','right']),
      '## Function-length heuristic: top 8','',
      'This is deliberately narrow and approximate: only JS/TS/Dart functions whose complete signature and opening brace are on one line are candidates. Comments and simple quoted strings are stripped, then physical lines are counted until braces balance. Multiline signatures are missed; regex literals, interpolation, unusual syntax, or braces in complex strings can distort spans. Use only as a triage signal, never a quality gate.','',
      table(['Function','File:line','Physical span'],[(name,f'{p}:{line}',span) for span,p,line,name in fspans],['left','left','right']),
      '## Cross-feature Flutter imports','',
      'Only literal Dart `import`, `export`, and `part` directives are scanned. Package paths resolve at `flutter_app/lib`; relative paths normalize from the importer. URI conditionals, interpolation, aliases and runtime references are ignored; self-feature edges are omitted.','',
      f'Unique directed feature edges: **{len(ec)}**; matching directives: **{sum(ec.values())}**.','',
      table(['Edge','Importing files','Directives'],[(f'{x} → {y}',len(ef[x,y]),ec[x,y]) for x,y in sorted(ec)],['left','right','right']),
      '### Cycles','',f'Strongly connected multi-feature components: **{len(cycles)}**. Components mean mutual reachability, not every simple cycle.','',
      ('\n'.join('- '+' ↔ '.join(c) for c in cycles)+'\n' if cycles else '_No multi-feature cycle found under these assumptions._\n')]
    er=[]
    for reason in ('frozen manifest roots','manifest active surfaces to remove','generated source','build/tool outputs','dependency outputs','design/media outputs'):
        members=excluded.get(reason,[]);sources=[p for p in members if PurePosixPath(p).suffix.lower() in EXT]
        er.append((reason,len(members),len(sources),f'{pl(sources):,}'))
    out+=['## Exclusions','',table(['Reason','Tracked files','Source files','Source physical lines'],er,['left','right','right','right']),
      f'Tracked files total: **{len(tracked):,}**. Eligible source files after path exclusions: **{len(code):,}**. Files outside exact headline definitions remain inventory only. Frozen CI test removals are classification removals in addition to path exclusions and are reported above.','',
      '## Reproduce','','```sh','python3 /tmp/architecture-metrics.py --repo "$(git rev-parse --show-toplevel)" --output /tmp/architecture-metrics.md','```','']
    Path(o.output).write_text('\n'.join(out),encoding='utf-8');print(o.output)
if __name__=='__main__':main()

```
