# Experience program — decisions log

Single source of truth for **locked product decisions**. Other docs in this program reference
decision IDs (`D1`, `D2`, …) instead of restating rationale. Add new decisions here first;
never silently change behaviour without a logged entry. Status values: `locked`, `tbd`
(implemented but explicitly open to revision), `deferred` (not in scope yet).

Source: agent/human chat, 2026-07-25 — analysis + Q&A rounds. See
[`briefs/`](briefs/) for the three original master briefs.

---

## A — Navigation reversal

| ID | Decision | Status | Phase |
|----|----------|--------|-------|
| **D1** | Navigation v2 (`docs/design/navigation-v2.md`) is **fully reversed**, not extended. It did not work for users. The new [`navigation-brief.md`](briefs/navigation-brief.md) model (hamburger = section switcher only; bell = notifications; no sitemap drawer) replaces it. | locked | Phase 1 |
| **D2** | `docs/design/navigation-v2.md` is kept as historical record, header-tagged **superseded**, not deleted. Same treatment `docs/experience-split-plan.md` already received. | locked | Phase R |
| **D3** | Events and Vets are **removed from the drawer** entirely. They surface only via dashboard preview sections + their own full screens (`/g/events`, `/g/vets`, `/o/vets`, org pets/fosters screens). | locked | Phase 1 |
| **D4** | The header "Home" button from nav v2 is also removed (not requested by the new brief, and reintroducing it would recreate the "generic Home" pattern D1 rejects). Header controls become: hamburger (section switch, dashboards) **or** back arrow (sub-screens), plus a persistent bell (all authenticated screens). | locked | Phase 1 |
| **D5** | Drawer is **not mode-dependent**. It always shows the same two peer items (Guardian, Organisation) plus bottom-pinned Account — never a long per-mode list. | locked | Phase 1 |
| **D6** | `org-mode-navigation-acf1` (branch `cursor/org-mode-nav-phase3-shell-acf1`, control issue #262) is **closed, not resumed**. Its only unmerged phase (router-file extraction) is superseded by Phase 3's from-scratch `organization_routes.dart` rewrite; merging then immediately rewriting wastes a review cycle. See Phase R for close-out steps. | locked | Phase R |

## B — Notifications (kind vs scope)

| ID | Decision | Status | Phase |
|----|----------|--------|-------|
| **D7** | Notifications have **two orthogonal axes**: `kind` (**Care** — health/weight/other-entry due items; **Administrative** — org/foster workflow items, approvals, sessions, messages, agreement-withdrawal alerts) and `scope` (`guardian` / `organization`, the existing enum, kept only as a *grouping label*, not a routing/screen split). A single foster user can receive Care-kind items with `scope=organization` (health reminder for a fostered pet) and Administrative-kind items with `scope=organization` (shelter message) — proving kind ≠ scope. | locked | Phase 1 |
| **D8** | One global bell, one unified full-height right slide-over. Badge = single combined unread count. Inside the panel: filter chips **All / Care / Organisation** (kind-based, reusing plum/green ownership-accent tokens) sit above the existing date-grouped list. For the ~98% guardian-only or guardian+foster population, the chips are low-friction (mostly everything is "Care" for guardian-only users) and become genuinely useful only once org/foster activity exists. | locked | Phase 1 |
| **D9** | "Resolved" state (distinct from "read") applies **only** to Administrative-kind notifications that reference an open actionable object (foster request, agreement-withdrawal alert, pending transfer/share/custody/adoption). Resolved is **derived** from the referenced object's state transition, not a manual dismiss. Care-kind items keep the existing read/unread-only model. | locked | Phase 1 |
| **D10** | The former dashboard-resident pending inboxes (pending shares, pending foster placements, pending adoption placements, pending custody transfers) **move into the Administrative notification feed** (unresolved until accepted/declined) instead of living as permanent dashboard banners. This resolves the Guardian dashboard's "where do these go" gap. | locked | Phase 2 |
| **D11** | Emergency/urgent Administrative notifications (e.g. agreement withdrawal) get a visually distinct treatment (warning/danger token leading icon, pinned above date order within the Administrative filter) but are **not** a third kind — still Administrative, just priority-flagged. | locked | Phase 4 |

## C — Roles and permissions (explicitly TBD)

| ID | Decision | Status | Phase |
|----|----------|--------|-------|
| **D12** | Target role/permission shape is **TBD by design** — hard to get a full functional lock now. Implement the shape in D13, but keep it explicitly flagged as revisable; do not treat any role/permission code path as final. | tbd | Phase 3/5 |
| **D13** | Working shape (draft): wire roles narrow to `associate \| foster \| admin \| super_admin` (4, reusing the existing `foster` org-membership flag which is already orthogonal to fostering *approval* per G0 §4.3). "Foster Admin / Pet Admin / Team Admin" from the brief become **named permission-key bundle presets** a Super Admin can apply to an `admin`-role member — built on G0's existing additive permission-key catalog (`docs/fostering-platform/g0-contract-pack.md` §7), not a parallel system. New `organization_permissions` override table (user_id, org_id, permission_key, granted_by, granted_at, revoked_at) carries both bundle-derived and individually-granted keys. | tbd | Phase 3 |
| **D14** | Associate = same base access as a plain member (no elevated default permissions), can be granted specific permission keys ad hoc. Not a new access tier by default. | locked | Phase 3 |
| **D15** | `manage_permissions` (grant/revoke other users' permission keys) defaults to Super Admin only, no exceptions today. Implemented as a **permission key check**, not a hardcoded role check, so a future exception only requires granting the key — no code change. | locked | Phase 3 |
| **D16** | Every permission grant/revoke and role change is written to the existing `audit_events` table (`docs/observability.md`) with new `event_type` values — fine-grained audit is non-negotiable. No new audit infrastructure; reuse existing retention tiers. | locked | Phase 3 |

## D — "Event" and pet timeline redefinition

| ID | Decision | Status | Phase |
|----|----------|--------|-------|
| **D17** | "Event" (Guardian dashboard "Upcoming Pet Events", `/g/events`) means **health events only**: due/overdue health entries, weight entries, and "other" entries. It is a computed/filtered view over existing domain data — **not** a new domain entity. "Add an event" = quick-add sheet routing to the existing health/weight/other-entry forms. | locked | Phase 2 |
| **D18** | The legacy "family events" concept (`family_events` table, `familyEventsRouter.js`, `organisation_pet_timeline.feature`) is **superseded** by a per-pet **Timeline** composed of: (a) human-guardian custody segments (start/end/note/guardian name — name visible only with permission) derived from `custody_transfers` history; (b) fostering-session cards (existing J3 read model, reused as-is); (c) a manual fallback entry (title/description/start/end) fillable by the guardian (human or org) when no system-derived segment exists ("No data" placeholder). Timeline lives on the **pet detail screen**, not the Guardian dashboard — it is a different feature from D17's Upcoming Pet Events. | locked | Phase 2 |
| **D19** | Remaining `family_events` rows not already migrated by migration `016` are one-time migrated into the new manual-timeline-entries table (preserving notes/dates), then `family_events` table + router are retired. | locked | Phase 2 |

## E — Discoverability

| ID | Decision | Status | Phase |
|----|----------|--------|-------|
| **D20** | Discover Organisations public fields (v1): name, logo, town/department (label follows locale — postcode/zip in other countries), description. Schema must stay flexible for future fields (current needs, species accepted, etc.) without repeated migrations — use a handful of typed columns now **plus** a reserved `public_profile_metadata JSONB` column, unused until a future phase defines its shape. | locked | Phase 3 |
| **D21** | Organisations are discoverable **by default**; Super Admin may opt out (`is_discoverable` flag). | locked | Phase 3 |
| **D22** | Discover/search is visible to **everyone, including logged-out users** — build it as a standalone reusable widget (no dependency on authenticated providers) so it can be dropped onto a future pre-login/landing screen without rework. The v1 delivery target is the authenticated Discover Organisations section; the widget's reusability is a design constraint now, not a second screen to build now. | locked | Phase 3 |

## F — Guardian-side small features

| ID | Decision | Status | Phase |
|----|----------|--------|-------|
| **D23** | Bulk share = thin Flutter-only multi-select wrapper around the existing single-pet share endpoint (loop per selected pet). No new backend bulk endpoint. | locked | Phase 2 |
| **D24** | Vet detail becomes **display-first** (Call/Email actions visible immediately); a separate edit mode/screen replaces today's edit-first `VetFormScreen` default. | locked | Phase 2 |

## G — Organisation presentation

| ID | Decision | Status | Phase |
|----|----------|--------|-------|
| **D25** | Everything that is "customisation of an organisation" — permissions/roles admin, journey/document/agreement/email templates, workflows — lives in **one place**: a section reached from the organisation's **edit screen**, visible to Super Admins only. | locked | Phase 5 |
| **D26** | Per-org self-management settings (an admin's own phone-visibility/notification prefs, a foster's own visibility/address/contact prefs) are reached **from that person's own card** inside the org (Admin Contacts / Fosters directory) — they are org-scoped, not global. | locked | Phase 3/4 |
| **D27** | Cross-org, personal settings (profile, cross-org notification defaults, help/FAQ/contact/legal/about, sign out) live under the global **Account** area (D1's navigation model), reached independently of any single organisation. | locked | Phase 1 |
| **D28** | Legal identity fields are **generic**: `legal_identifier_1/2/3` (nullable strings, none compulsory) on `organizations`, with **localised labels** (e.g. FR locale shows "Numéro RNA" / "SIREN" / "SIRET"; other locales show generic "Legal identifier N" or hide the block) via ARB keys — no hardcoded French-only schema. | locked | Phase 3 |
| **D29** | Cover image + round logo hero is not a hard v1 requirement but should reuse the existing upload plumbing already in `organization_branding_section.dart` (image_picker + existing static-asset serving). Always state explicit size/type guidance in the upload UI copy. | locked | Phase 3 |
| **D30** | Agreement withdrawal triggers **auto-pause** of the foster's active/preparation fostering sessions (flag for admin review, not silent auto-cancel) **and** an urgent Administrative notification (D11) to all admins/super-admins of that organisation. This must remain a genuinely rare, high-friction, "something needs human attention" path — not a routine status change. | locked | Phase 4 |
| **D31** | Foster/admin self-management visibility controls **reuse and extend** the existing `notification_preferences` entity and the existing DPIA/retention model (`regulatory/internal/dpia-foster-directory.md`, G0 §11/§17) rather than inventing a parallel privacy model. | locked | Phase 3/4 |

## H — Delivery process

| ID | Decision | Status | Phase |
|----|----------|--------|-------|
| **D32** | A dedicated **Phase R (Reconciliation)** runs before Phase 0, closing out D2/D6 and tagging affected BDD scenarios `@legacy` per the existing G0 §14.2 pattern. | locked | Phase R |
| **D33** | Default delivery mode is **single-agent, sequential, direct-to-`main` per phase** (merge-policy.mdc "single-agent / single-domain PRs → main"). `/spawn-sprint-agents` stays available as an option for any phase where disjoint-path parallelism is later judged worthwhile (e.g. Phase 3 admin-contacts vs pet-tabs), but is not the default plan. | locked | All |

---

## How to use this log

- New decision discovered mid-implementation → add a row here **first**, then implement.
- A decision proves wrong during a phase → do not silently code around it. Update the row
  (status `tbd` → new status), note the phase/PR that revised it, and flag in that phase's
  "Open questions" section.
- Phase docs and the program contract **link to decision IDs**; they do not re-explain rationale.
