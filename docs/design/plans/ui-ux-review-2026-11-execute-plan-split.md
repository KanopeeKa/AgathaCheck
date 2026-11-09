---
title: UI/UX review (November 2026) — splitting the fixes into three execute-plans
owner: Documentation Team
audience: both
status: draft
last_updated: 2026-11-09
tags: [design, ui, ux, review, execute-plan, planning]
---
# UI/UX review (November 2026) — splitting the fixes into three execute-plans

This document weighs implementation options only. It does not re-check or re-grade the findings of the
November 2026 UI/UX review of all active screens. It asks one question: can the review's three
suggested tracks run as three separate `/execute-plan` (v2) programmes, and if so, how should they be
cut so that they don't block each other? Plan files and snapshots are not written here.

Finding IDs (A-…, B-…, C-…, D-…, X-…) and Part 5 sections refer to that review. Execute-plan rules come
from [`execute-plan-v2.md`](../../agent-efficiency/plans/execute-plan-v2.md), its
[`contracts.md`](../../agent-efficiency/plans/execute-plan-v2/contracts.md), the scope checker
(`scripts/lib/execute_plan_scope.js`) and the safety gate (`.github/scripts/agent-safety-lib.js`), as
read on 2026-11-09.

## 1. Verdict

**Feasible, with three conditions.** Three plans can run at the same time, because execute-plan v2
gives each plan its own integration branch, lease, budgets and release PR. Run naively, though, they
collide in about a dozen files and in both ARB files, and two of the tracks hit paths that no plan PR
is allowed to change. The recommended shape:

1. **A small "phase 0" PR straight to `main`, before any plan starts.** It holds the shared
   async-state primitives (`AsyncErrorState`, `SupplementalStateCaption`, labelled progress) that
   tracks 1 and 2 both build on.
2. **A file-ownership map**, enforced with each plan's `forbidden_paths`, so that every contested file
   belongs to exactly one plan (§4).
3. **Track 3 cut down to what an autonomous plan may touch.** The CI lane, workflow and pre-push
   changes, the data decisions and the production checks become owner PRs or owner tasks outside the
   plan (§3.3, §5).

Under these conditions, plans 2 (invites) and 3 (frozen-code removal) can start together. Plan 1
(async-state roll-out) can start at the same time or one phase later. The ARB files stay the one
shared hotspot; §4.3 covers how to keep it manageable.

## 2. Execute-plan constraints that shape the split

| Constraint | Source | Effect on this split |
|---|---|---|
| 1–8 phases per plan, one PR each | `V2_CAPS.phases = 8`, contracts §3.1 | Track 3 (Part 5 § 5.7 steps 2–6) already fills 8 phases. Anything else has to go elsewhere. |
| Approval window ≤ 14 days (default 7); resume renews it | `V2_CAPS.window_days`, contracts §3.3 | Track 3 will almost certainly need at least one `resume-autonomous`. |
| Phases run strictly in order, one worker per plan | non-goal "parallel phases", lease | A plan can't wait for another plan mid-way. Order *inside* each plan is the only sequencing tool. |
| Protected paths: no plan PR may change `.github/**`, `scripts/pre-push.sh`, `scripts/pre-push-changed.sh`, `.claude/**`, `.cursor/rules/**`, `AGENTS.md`, `CLAUDE.md`, `.agents/plans/**` | `PROTECTED_PATHS` in `execute_plan_scope.js` | Part 5's "delete the frozen CI lane and exclusions" can't be a plan phase (§3.3). |
| Forbidden unless the phase lists `approved_sensitive_paths`: any path with `/auth/`, `/billing/`, `/secrets/`, `db/migrations/`, `server/config/security.js` | `agent-safety-lib.js`, scope rule 3b | Landing, My details, Secure account, Forgot password (`flutter_app/lib/features/auth/**`) and `server/routes/auth/**` all need an explicit sensitive-path approval. |
| Escalation: security, breaking API, production data migration, CI gate change, product decision | `autonomous-pr-policy.md` § Escalation | Decide these before approval; otherwise the plan stops mid-flight (§5). |
| Fixed companions include `flutter_app/lib/l10n/*.arb`, `**/*.g.dart`, `**/generated/**` | `FIXED_COMPANIONS` | ARB edits are always allowed. The generated `flutter_app/lib/l10n/app_localizations*.dart` files are **not** covered and must be in `allowed_paths` or `companions` of every phase that adds strings. |
| Driver passes for all plans share one concurrency group | `.github/workflows/execute-plan-driver.yml` (`group: execute-plan-driver`) | Three active plans progress more slowly per plan (the 30-minute heartbeat catches up). This slows them down but doesn't break them. |
| Each release PR targets `main`; the others then need a sync | sync / sync-resolve, budget 5 | Overlapping files turn into sync-resolve PRs. Stagger the releases (§6). |
| Workers only see the repository | worker handoff prompt | **The source review must be committed before approval.** Workers cannot follow "see B-2.1" unless the nine-part specs are in the repo. The review's relative links resolve from `docs/design/plans/`, beside this file. |

## 3. The three plans

### 3.1 Plan 1 — Async state roll-out (X-1, X-2, X-7)

**Goal (one sentence):** every failed primary load on the active screens shows localized copy with
Retry inside the shell, and no supplemental failure looks like "none" or "all clear".

**Depends on:** the phase-0 primitives (§3.4). Without them, phase 1 of this plan must build them, and
Plan 2 either waits for this plan to release or duplicates the widgets.

| Phase | Scope (finding IDs) | Main paths |
|---|---|---|
| 1 | Home and pets: B-2.1, B-3.1, B-4.1, B-5.1, B-6.1 | `features/experience/presentation/screens/**`, `pet_profile/screens/**`, `pet_edit_permission_guard.dart` |
| 2 | Care: B-7.1, B-8.1, B-8.2, B-10.2, B-11.1, B-12.2, B-13.1, B-14.1, B-14.2 | `experience/presentation/care_item/**`, `pet_profile/screens/**`, `health_tracking/presentation/screens/health_entry_form_screen*.dart`, `weight_tracking/presentation/screens/**` |
| 3 | Away plans: C-1.1, C-1.2, C-2.1, C-3.1, C-3.2, C-4.1 | `features/pet_care/context/presentation/screens/planned_absence_{hub,flow,plan,edit}_screen.dart` and their widgets |
| 4 | People and households: C-7.1, C-8.1, C-9.1, C-10.1, C-10.4, C-11.1 | `features/people/presentation/**` except household invite landing |
| 5 | Sharing management: C-12.1, C-12.2, plus removing the inactive foster/organisation branches in `share_pet_screen.dart` (Part 5 § 5.3, owned here, see §4) | `features/sharing/**` except the three recipient files owned by Plan 2 |
| 6 | Account, notifications, subscription, legal: D-2.5, D-2.2, D-4.3, D-5.1, D-5.2, D-7.5, D-11.3 | `pet_tags/**`, `notifications/presentation/screens/**` and `widgets/notification_panel_error_view.dart`, `subscription/presentation/**`, `about/presentation/**` |
| 7 (optional) | Canonical docs, BDD/Playwright error-path coverage, fold reusable rules into `docs/design/system.md` | `docs/domains/**`, `docs/design/system.md`, `e2e/**` |

**Out of scope for this plan:**

- Auth and entry screens: A-2.4, A-5.6 and A-8.3 are form errors (X-5), not load errors, and sit on
  forbidden `/auth/` paths. A-3.3 lives in the resolver, which Plan 2 owns.
- The four recipient landings (Plan 2).
- Any file on the Part 5 § 5.6 delete list (Plan 3).

**Risk profile:** low to medium. The change is mostly mechanical once the primitives exist, the paths
aren't sensitive and the API is unchanged. One real unknown: B-10.2 ("what Save does after a failed
edit load"). Verify it before approval and write the answer into the phase-2 exit checklist.

**Proof on UAT:** hard to show on a healthy environment. The proof should be widget and integration
tests with injected failures, plus one UAT check with the browser offline on Home and Pet detail.

### 3.2 Plan 2 — Invite recipients (X-3)

**Goal:** a signed-out person who opens any of the four invitation links sees who invited them and
what they get, can sign in or create an account, returns to the same invite, and must still accept
explicitly.

| Phase | Scope | Main paths |
|---|---|---|
| 1 | Return-to-invite contract: one list of public recipient prefixes (adding `/absence-invite/`), validated `returnTo` carried through login, native login, signup and onboarding, no auto-accept; the shared recipient block; A-3.3 resolver error state | `core/router/app_router.dart`, `features/auth/presentation/screens/landing_screen.dart` **(sensitive)**, `features/experience/presentation/screens/experience_resolve_screen.dart`, a new `core/widgets/` recipient block |
| 2 | Share link and email invite: C-13.1, C-13.3, C-13.4, C-14.1, C-14.2, C-14.3 (C-13.2 only once the preview policy is decided) | `sharing/presentation/screens/{shared_pet_screen,invite_landing_screen}.dart`, `widgets/shared_pet_accept_section.dart` |
| 3 | Away invite: C-15.1, C-15.2, C-15.3, replacing `/login?redirect` | `pet_care/context/presentation/screens/absence_invite_landing_screen.dart` |
| 4 | Household invite: C-16.1, C-16.2, C-16.3 (structured preview errors) | `people/presentation/households/household_invite_landing_screen.dart`, `people/data/households_api.dart` |
| 5 | Journey coverage: Gherkin plus Playwright for signed-out → auth → return → explicit decision on all four routes; canonical docs (sharing, people, pet_care away, auth) | `e2e/**`, `docs/domains/{sharing,people,pet_care,auth}/**` |

**Risk profile:** highest impact (four of the review's eight High findings) and the one track with a
security surface. `returnTo` is an open-redirect vector, and the landing screen is on a forbidden
path. Recommendations:

- list `flutter_app/lib/features/auth/presentation/screens/landing_screen.dart` (and only that file)
  in phase 1's `approved_sensitive_paths`;
- set `settings.release_owner_review: true`, so a human reviews the release PR before it reaches
  `main`;
- have the owner sign off on the `returnTo` validation rule (same origin, one of the four recipient
  prefixes, nothing else) in the plan's Goal before approval. That is a security decision, and
  leaving it open makes the plan stop.

**Proof on UAT:** naturally observable. Open each of the four links in a private window on UAT,
create an account, and land back on the same invite with Accept and Decline visible.

### 3.3 Plan 3 — Frozen Shelter/Fostering removal (Part 5)

**Goal:** the frozen Shelter/Fostering product code and the dead active widgets are gone from
`flutter_app/lib` and `server/`, and no active screen describes those features. Data and CI machinery
stay as they are.

The review's eight steps (Part 5 § 5.7) do not all fit one plan:

| § 5.7 step | Where it belongs | Why |
|---|---|---|
| 1 — tag `main`, removal record, count production pets with `organization_id`, confirm no frozen notification producers | **Owner tasks before approval** | Tags and production queries are owner actions, and their results are inputs to the plan's scope |
| 2 — Flutter frozen roots | Plan 3, phase 1 | Disjoint from everything else; pure deletion |
| 3 — server roots | Plan 3, phases 2–3 | Migrations `023`, `028`, `042` and the auth routers need decisions first (§5) |
| 4 — dead active code (§ 5.6) | Plan 3, phases 4–5 | `LoginScreen`, `SignupScreen` and the `features/auth/auth.dart` barrel are sensitive paths |
| 5 — active semantics and content (X-4) | Plan 3, phases 6–7 | Touches files other plans need; ordered last on purpose (§4) |
| 6 — boundary machinery and docs | **Split:** docs in Plan 3 phase 8; CI lane, workflow steps, pre-push exclusions in **an owner PR after Plan 3 releases** | `.github/**` and `scripts/pre-push*.sh` are protected. `_reusable-test.yml` still runs `scripts/check_frozen_domain_boundaries.sh` and its fixture test, and `scripts/check_file_size.js` / `scripts/lib/active-server-universe.js` read `docs/engineering/frozen-domains/manifest.json`. Plan 3 must therefore **keep** the script, its fixture test and the manifest (roots may point at deleted folders) until the owner PR removes the workflow steps. |
| 7 — password-manager bridge | **Not in any of the three plans** | Auth surface and independent of removal; a later plan or PR series |
| 8 — data decision | **Separate track** with the data-protection owner | Production data, out of scope for agents |

Resulting phases:

| Phase | Scope | Notes |
|---|---|---|
| 1 | Delete `features/organization/`, `features/fostering_session/`, their tests, the `analysis_options.yaml` exclusion | ~31,000 lines; exit = `flutter analyze` on the whole tree, active tests green |
| 2 | Make migrations `023`, `028`, `042` self-contained (move or inline what they import from `server/lib`) | Owner decision on the approach first; the migrations' SQL must not change |
| 3 | Delete server routes, frozen libs, e-mail templates, seeds, `server/test/organizations/`, `jest.config.frozen.cjs`, `scripts/test-frozen-domains.sh`, mount gate; frozen BDD features and Playwright specs (move shared helpers first) | Replace the `rejectFrozen*` call sites in active pet routes. Leave `server/routes/auth/**` alone unless the retire/keep decisions in §5 are made |
| 4 | Dead active code, batch 1 (§ 5.6.1 groups) | Re-point or keep the three test shims (§ 5.6.3) |
| 5 | Dead active code, batch 2 (§ 5.6.2) including `LoginScreen`, `SignupScreen`, barrel exports, the dead `/login` literal in My details | `approved_sensitive_paths` for exactly those `features/auth/**` files |
| 6 | Single-valued `AppExperience`, shell toggle (B-1.2), chooser (A-4.1), pet-form org branches (B-5.2), org filter chips, frozen notification kinds and Pending actions retirement (D-6.x), notification matrix frozen category (D-5.3) | Router edits (frozen stubs, `/app/choose`, `/pending-actions` redirect) are the **only** `app_router.dart` changes in this plan; see §4.2 |
| 7 | Content pass (X-4): Help (D-8.x), Account (D-1.1), About tagline (D-9.3), My details org row (A-7.4, sensitive), `web/index.html` meta description | New and removed strings in both ARBs |
| 8 | Removal record replacing `docs/engineering/frozen-domains/*` (keep `mvp-pivot-decisions.md` and the manifest), `terminology.md`, `docs/design/index.md`, `.agents/memory` notes | The unused-ARB-key sweep is **not** here (§4.3) |

**Risk profile:** largest diff, lowest visible behaviour change, and the most owner decisions. The
plan sits at the 8-phase cap with no slack. If a phase has to be split, the content pass (phase 7) is
the one to move out, as a small follow-up PR or into a later plan.

### 3.4 Phase 0 — shared primitives on `main` (single-agent PR, not a plan)

- `AsyncErrorState` (B-2.1 "Implementation notes"), `SupplementalStateCaption` (B-3.1, B-4.1), and one
  labelled progress / live-region status widget (B-12.2, X-7), all in `flutter_app/lib/core/widgets/`.
- Their EN/FR ARB keys, widget tests, and a short entry in `docs/design/system.md` § 6.10.
- No call-site changes. This keeps the PR small, so it merges in a day, and both plans branch from a
  `main` that already has the widgets.

Alternative: make this Plan 1's phase 1 and start Plan 2 only after Plan 1 releases. That serialises
the highest-impact track behind the broadest one. Not recommended.

## 4. File ownership and conflicts

### 4.1 Contested files and the proposed owner

| File / area | Wanted by | Owner | How the other plan is kept out |
|---|---|---|---|
| `core/router/app_router.dart` | Plan 2 (public prefixes, `returnTo`), Plan 3 (frozen stubs, chooser, pending-actions redirect) | **Plan 2** first, then Plan 3's phase 6 | Plan 3 lists it in `forbidden_paths` for phases 1–5; only phase 6 allows it, and that phase normally runs after Plan 2 has released (§6). |
| `experience_resolve_screen.dart` | Plan 2 (`returnTo`, A-3.3), Plan 3 (A-3.1 simplification) | **Plan 2** | Plan 3 simplifies `experience_providers.dart` only, and forbids the resolve screen. |
| `features/auth/presentation/screens/landing_screen.dart` | Plan 2 (`returnTo`), Plan 3 (nothing), the later bridge work | **Plan 2** | Not in Plan 3's sensitive-path list. |
| `features/sharing/presentation/screens/share_pet_screen.dart` and sharing widgets | Plan 1 (C-12.1, C-12.2), Plan 3 (foster/org branches) | **Plan 1**, which removes the inactive branches during its rewrite | Plan 3 forbids `flutter_app/lib/features/sharing/**`. |
| `shared_pet_screen.dart`, `invite_landing_screen.dart`, `shared_pet_accept_section.dart`, the absence and household invite landings | Plan 1 (their X-1 errors), Plan 2 | **Plan 2**, including their error findings | Plan 1 forbids these five files. |
| `pet_care_due_events_screen.dart` (live All actions + dead `OrgDueEventsScreen`) | Plan 3 (delete the dead classes) | **Plan 3** | Plan 1 doesn't need it (B-9 is not in the X-1 roll-out). |
| `notification_settings_screen.dart` / `notification_settings_matrix_section.dart` | Plan 1 (D-5.1, D-5.2) / Plan 3 (D-5.3 frozen category) | Split by file | Each plan forbids the other's file. |
| `account_screen.dart`, `help_screen.dart`, `about_screen.dart`, `pending_actions_screen.dart` | Plan 3 (content, retirement) | **Plan 3** | Plan 1's phase 6 forbids them. |
| `my_details_screen.dart` and `profile_settings_section.dart` (sensitive) | Plan 3 (org row, `/login` literal) | **Plan 3** | Not touched by Plans 1 and 2; the A-7 truthful-outcome fixes stay outside all three (§7). |
| Files on the § 5.6 delete lists | Plan 3 (delete) | **Plan 3** | Plan 1 adds the § 5.6 list to `forbidden_paths`, so it never fixes a file that is about to disappear. |

### 4.2 Why the conflicts don't vanish entirely

`forbidden_paths` stops a plan from *changing* a file. It doesn't stop the file from changing on
`main` under the plan. Each release to `main` triggers sync PRs in the other plans. With the map
above, the remaining real conflict is `app_router.dart` between Plan 2 and Plan 3's phase 6. That's
a small, local conflict, within the sync-resolve budget of 5.

### 4.3 The ARB files (unavoidable hotspot)

All three plans add or remove strings in `app_en.arb` and `app_fr.arb`, and the generated
`app_localizations*.dart` files change with them. Mitigations, in order of value:

1. **No unused-key sweep in any of the three plans.** Part 5 § 5.3 ends with removing every key no
   code references. Done while two other plans are adding keys, it guarantees a conflict on every
   sync. Run it once, as a single follow-up PR, after all three have released.
2. **Insert new keys next to their feature's existing keys, not at the end of the file.** Appending
   at the end from three branches produces adjacent-line conflicts every time.
3. **Name the generated files explicitly** in `companions` for every phase that edits ARB. The sync
   resolver then regenerates them (`flutter gen-l10n`) instead of merging them by hand.

## 5. Decisions needed before approval

A plan stops (`needs-owner`) when it reaches one of these mid-flight, so they belong in the Goal or
scope block up front.

| Plan | Decision | Escalation class |
|---|---|---|
| 1 | B-10.2: what Save does after a failed edit load (verify first) | none if verified; data integrity if not |
| 2 | `returnTo` validation rule and its allow-list | Security |
| 2 | C-13.2: which fields an anonymous shared-pet preview may show | Product / privacy |
| 2 | Sensitive-path approval for `landing_screen.dart` | Safety gate |
| 3 | Method for making migrations `023`, `028`, `042` self-contained without changing their SQL | Production data migration |
| 3 | `POST /pets/:id/transfer-to-org`, `pinned_organization_id`, memberships in login and `/me`: retire or keep returning an empty value | Breaking API |
| 3 | Confirmation that no producer still emits foster, adoption or custody notification kinds | Product |
| 3 | Production count of pets with a non-null `organization_id` (§ 5.4); no code change depends on it yet, but it should be known before deleting the routes that served them | Data |
| 3 | Sensitive-path list for `LoginScreen`, `SignupScreen`, the auth barrel, My details | Safety gate |
| 3 | The owner PR that removes the frozen CI lane, workflow steps and pre-push exclusions after release | CI gate change (owner-only, protected paths) |

## 6. Options for running them

| Option | How | For | Against |
|---|---|---|---|
| **A. All three in parallel from day one** | Approve all three snapshots together | Fastest wall-clock time | Plan 2 needs the primitives (unless duplicated); the most sync-resolve work; three release PRs racing to `main`; the owner reviews three control issues at once |
| **B. Sequential: 3 → 1 → 2** | Removal first, then roll-out, then invites | Fewest conflicts; Plan 1 never touches dead code | Highest-impact fixes (Plan 2) land last, weeks later; Plan 3's decisions (§5) block everything |
| **C. Phase 0, then 2 ∥ 3, then 1 one phase behind (recommended)** | Merge phase 0; approve Plans 2 and 3 together; approve Plan 1 once phase 0 is on `main` (it can start the same day) | High findings in Plan 2 start immediately; Plan 3's early phases are pure deletion and touch nothing the others own; ownership map plus `forbidden_paths` keeps PRs within scope | Needs the ownership map written into three snapshots; still one router conflict and ARB syncs |

With option C, the expected release order is **Plan 2 (5 phases) → Plan 1 (6–7) → Plan 3 (8)**.
That order is convenient: Plan 3's router and content phases come last, after the other two have
released, so its syncs absorb their changes once. If Plan 3 runs ahead, its phase 6 meets the router
conflict in a sync-resolve PR. That costs some budget but isn't a stop.

Operating notes for any option:

- **Throughput.** All driver passes share one concurrency group. Each plan advances at most one
  action per pass, and pending dispatches can be replaced, so expect roughly half-hour steps when all
  three are busy.
- **CI minutes.** Each phase PR runs full CI, and each release triggers pre-UAT and UAT promotion.
  Three programmes roughly triple Actions usage during the overlap. Keep each phase's
  `exit_checklist` concrete so phases don't burn CI attempts on avoidable mistakes.
- **Release spacing.** Let one release clear UAT promotion before the next release PR is armed.
  Otherwise the second release is out of date the moment the first merges, and its CI runs again.
- **Approval window.** Plan 3 will outlive a 7-day window. Approve it with the 14-day maximum, or
  expect a `resume-autonomous`.

## 7. What none of the three plans covers

The three tracks close X-1, X-2, X-3, X-7 (partly) and X-4, plus Part 5. They leave out several
findings the review ranks highly:

| Finding(s) | Why it matters | Suggested vehicle |
|---|---|---|
| D-7.1, D-7.2 (High) — inert "Manage subscription", no renewal disclosure | Billing trust | Two small standalone PRs; D-7.2 needs store metadata checked |
| D-12.1 (High) — native export reports success without a file | Data rights | Standalone PR (sensitive path `features/auth/**`) |
| D-4.1 (High) — shell bell has no route to full inbox or settings | Reminders are the main trust channel | Standalone PR; small |
| A-10.5 — compact consent banner `Expanded` in an unbounded column | Can break the first-use privacy decision | Standalone PR; small |
| A-7.2, A-7.5, A-7.6, A-8.x, D-12.2 — truthful outcomes in auth forms (X-5) | Validation and false-success messages | A later "X-5 truthful outcomes" plan, or a short PR series, after Plan 3 removes the dead auth screens |
| X-6 literal-string lint, X-8 text-scale pass, X-9, X-10 token pass | Systemic quality | Later plans; best after the three land, when files have settled |
| X-12 password-manager bridge (Part 5 § 5.5) | Sign-up gap | Its own plan; auth-sensitive |
| **X-13 — CSP blocking the fallback font (needs verification)** | If confirmed, all Flutter text is missing on web | **Verify first, before any plan's "Proof on UAT".** A UAT proof captured with text missing proves nothing |

## 8. Before writing the plan files

1. Commit the source review to `docs/design/plans/` (its relative links resolve from there). Workers
   need the nine-part specs.
2. Run the X-13 check on UAT.
3. Land phase 0 on `main`.
4. Take the §5 decisions and record them in the canonical docs (decision-log rows) or in each plan's
   Goal.
5. Write the three plan files with the ownership map (§4.1) as `forbidden_paths`, the generated l10n
   files as companions, and the sensitive-path lists. Then run `init` → approve.
