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

## Guardian Today dashboard contract

| ID | Decision | Status | Phase |
|----|----------|--------|-------|
| **D34** | Guardian `/g/home` remains exactly three management sections: **My Pets**, **Due and Overdue**, and **My Vets**. **Today** is a compact orientation/prioritisation layer above them, not a fourth section, management screen, or new route. | locked | Phase 2 |
| **D35** | The dashboard preview is capped at **4 pets** and **5 care items**. Pet previews use bounded rectangular cards with an approximately **96–112 px** photo region, accessible placeholders, and ownership/status text or icon support. My Vets remains an uncapped compact, scannable row list unless separately revised. | locked | Phase 2 |
| **D36** | Guardian Today is presentation-only over existing providers and helpers. Ownership/relationship semantics, due ordering, server-authoritative completion/undo, retryable error states, existing routes, and global notifications remain unchanged. “Events” continues to mean computed health/weight/other care entries under D17, never a new generic event entity. | locked | Phase 2 |
| **D37** | A five-tab bottom bar, universal Add action, and new Today route are deferred from this branch. They require a separate decision covering shared Guardian/Organisation shell semantics, root/back/deep-link behavior, Add scope and permissions, accessibility, and native portability. | deferred | Future navigation decision |

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

## I — Organisation v2 (profile composer)

| ID | Decision | Status | Phase |
|----|----------|--------|-------|
| **D-v2-IA-1** | `/o/orgs/:id` is a **profile composer** (header + stacked sections), not a link-only dashboard. | locked | v2 Slice 2 |
| **D-v2-IA-2** | `/o/orgs/:id/presentation` **redirects** to profile — no separate primary destination. | locked | v2 Slice 2 |
| **D-v2-IA-3** | Discover tile tap → profile route; **non-members see public tier only** (opted-out orgs → 404). | locked | v2 Slice 3 |
| **D-v2-IA-4** | Profile shows **12 pets** (preview), sorted by last activity. | locked | v2 Slice 4 |
| **D-v2-PERM-1** | Formal **`view_*` permission keys** + `GET /organizations/:orgId/permissions/me`. | locked | v2 F0 |
| **D-v2-PERM-2** | **Associates** see 12-pet preview; pet tap opens **redacted org pet profile** (Option B) — no timeline, sessions, health, documents unless granted. **Server-enforced.** | locked | v2 Slice 4 |
| **D-v2-PERM-3** | Admin contact tile subtitle = existing **role label** (Admin, Super Admin, etc.). | locked | v2 Slice 4 |
| **D-v2-PERM-4** | Permission overrides are **additive grants only** — no deny overrides. | locked | v2 F0 |
| **D-v2-ACT-1** | `pet_activity_events` + `pets.last_activity_at`; **no backfill**. See `docs/architecture/pet-activity-model.md`. | locked | v2 Slice 1 |
| **D-v2-ACT-2** | Foster update activity = session mutations + foster-visible health/document writes. | locked | v2 Slice 1 |
| **D-v2-ACT-3** | Activity events carry **no sensitive payloads** (metadata keys/counts only). | locked | v2 Slice 1 |
| **D-v2-PUBLIC-1** | Non-discoverable or opted-out orgs return **404** on public profile for non-members. | locked | v2 Slice 2 |
| **D-v2-FILTER-1** | Shadow / Rainbow Bridge filters remain **additive** (union onto tab results). | locked | v2 Slice 7 |
| **D-v2-ADDR-1** | Postcode in `public_profile_metadata.postcode`; discover uses server-computed `display_locality`. | locked | v2 Slice 3/5 |
| **D-v2-MSG-1** | Message actions = **mailto/tel** everywhere. | locked | v2 Slice 4 |
| **D-v2-NOTIF-1** | In-app notifications only; email deferred. | locked | v2 Slice 7 |
| **D-v2-NOTIF-2** | Placement side-effects at **repository boundary** (invalidate pending + notification providers). | locked | v2 Slice 7 |
| **D-v2-CONN-1** | Connected-org disconnect = **simple confirm** (no typed REMOVE). | locked | v2 Slice 4 |
| **D-v2-SESSION-1** | Sessions list on `foster_placements`; `/direct-adopt` stays until future unification. | locked | v2 Slice 6 |
| **D-v2-BDD-1** | `@legacy` scenarios remain in BDD gate denominator. | locked | v2 Slice 8 |
| **D-v2-ROLL-1** | Deep routes (pets list, sessions, admin directory) **remain**; profile changes entry points only. | locked | v2 |

### Organisation UX v3 (2026-08-04)

Source of truth: [`organisation-ux-v3-delivery-plan.md`](organisation-ux-v3-delivery-plan.md). Execute-plan: `organisation-ux-v3-badd`.

| ID | Decision | Status | Phase |
|----|----------|--------|-------|
| **D-v3-VIS-1** | Organisation drawer item **hidden by default**; shown if toggle on **or** user is org member (toggle forced on + disabled with explanation). | locked | v3 Phase 2 |
| **D-v3-VIS-2** | Default-experience **radios removed** (Account + My Details). Login restores **last active section**. | locked | v3 Phase 2 |
| **D-v3-IA-1** | Org profile member sections are **nav rows only** (optional counts) — **no previews**. Supersedes **D-v2-IA-4** as primary profile IA for pets/people/connections. | locked | v3 Phase 7 |
| **D-v3-IA-2** | Discover is a **dedicated screen**; dashboard has a Discover nav row only. | locked | v3 Phases 4–5 |
| **D-v3-IA-3** | “Organisation Administration” (renamed customisations) is a **profile nav row only** (same privileges). Supersedes **D25** entry-point rule. | locked | v3 Phase 7 |
| **D-v3-IA-4** | Delete organisation on **Edit** only; profile Leave **redirects** to Account per-org settings. | locked | v3 Phases 6, 8 |
| **D-v3-NAV-1** | Org scaffold: light teal. Dashboard: Agatha logo + title + bell + `+`. In-org: org logo thumbnail + title + bell (no Agatha except dashboard; no org logo on profile nav). | locked | v3 Phase 3 |
| **D-v3-NAV-2** | Nav titles: `titleMedium` → wrap 2 lines → ≥12sp → ellipsis. | locked | v3 Phase 3 |
| **D-v3-DISC-1** | Discover search via server `?q=` (name), debounced; pagination preserved. | locked | v3 Phase 5 |
| **D-v3-DISC-2** | Discover remembers entry context + “browsing as {user\|org}” banner. | locked | v3 Phase 5 |
| **D-v3-TILE-1** | My Orgs / Discover / people tiles follow pet-tile sizing; no-hero My Orgs = solid teal. | locked | v3 Phases 4, 5, 9 |
| **D-v3-TILE-2** | Role separator colours + **role label** (a11y): Super Admin black / Admin teal / Foster light teal / Associate white / pending grey / external foster = foster. | locked | v3 Phase 9 |
| **D-v3-MSG-1** | People tiles: in-app message only (no mailto); phone if allowed. Full messaging **deferred** (DEF-MSG). | locked | v3 Phase 9 |
| **D-v3-PRIV-1** | Per-org privacy + Leave under **Account → org settings** (one screen per org). Supersedes **D26** entry point. | locked | v3 Phase 8 |
| **D-v3-PRIV-2** | Visibility defaults/floors per role matrix in v3 delivery plan (incl. named-person grants). Super Admin always sees member name. | locked | v3 Phase 8 |
| **D-v3-EDIT-1** | Edit unboxed; Upload cover / Upload logo; ~96px hero logo; name band right of logo. | locked | v3 Phase 6 |
| **D-v3-UPLOAD-1** | Cover/logo upload success for valid ≤2MB JPG/PNG/WebP; clear UI errors from server. | locked | v3 Phase 1 |
| **D-v3-NOTIF-1** | No org-notification profile section this plan; unified bell unchanged. Full org-admin notification product **deferred** (DEF-NOTIF). | locked | v3 |

### Organisation people, permissions & foster v4 (2026-08-06)

Source of truth: [`organisation-people-permissions-v4-delivery-plan.md`](organisation-people-permissions-v4-delivery-plan.md).

| ID | Decision | Status | Phase |
|----|----------|--------|-------|
| **D-v4-PEOPLE-1** | Unified **People** screen at `/o/orgs/:id/people` lists all org people (members, external fosters, pending invites) in one grid — self card pinned first, then alphabetical by last name. Everyone in the org may open the screen; per-tile actions respect viewer permissions. | locked | v4 Phase B |
| **D-v4-PEOPLE-2** | **Admin contacts** dedicated screen is **removed**. Profile nav row label stays **Admin contacts** but routes to People with `filter=admins` (admin + super_admin wire roles). No second directory screen. | locked | v4 Phase B |
| **D-v4-ROLE-1** | Wire roles narrow to **`associate \| admin \| super_admin`** — the `foster` wire role is **retired**. Existing `organization_users.role = foster` rows migrate to `associate`. Fostering is **not** a wire role. Supersedes D13 foster wire role. | locked | v4 Phase C |
| **D-v4-ROLE-2** | Minimum app membership role is **associate**. External/manual fosters (`org_foster_parents` without user account) have **no wire role** — foster identity is badge + relationship only. | locked | v4 Phase C |
| **D-v4-FOSTER-1** | Fostering status is a **badge** on people tiles and person profile (orthogonal to associate/admin/super_admin). Onboarding cannot be granted by a permission toggle — dedicated foster onboarding flow only. | locked | v4 Phase C/G |
| **D-v4-PERM-1** | Roles & Permissions editor uses **staged changes + single Save** and **leave-without-save** warning. No immediate API call per toggle. | locked | v4 Phase E |
| **D-v4-PERM-2** | Bulk permission UI: when selected people disagree on a key, control shows **indeterminate (centre)** position; changing it applies uniformly to all selected. Pending edits show a neutral marker (blue disc or arrow — same size for all). | locked | v4 Phase E |
| **D-v4-PERM-3** | Top preset buttons are **Apply Associate**, **Apply Admin**, **Apply Super Admin** (replacing Apply Foster/Pet/Team Admin as role shortcuts). Foster Admin / Pet Admin / Team Admin remain **group headers** in the detailed permission list only. Preset buttons manipulate toggles; persistence is **per permission key**. | locked | v4 Phase E |
| **D-v4-PERM-4** | Clicking a role preset sets ON all keys in that org's default set for the tier and OFF keys outside it (**resets extra individual grants** for the selection) — confirm before Save. | locked | v4 Phase E |
| **D-v4-PERM-5** | Org-level **default permission sets** per tier (associate / admin / super_admin) are editable under Organisation Administration; saving applies org-wide with **confirmation** warning that individuals may need manual adjustment. Defaults layer on G0 baselines (both apply). Super-admin tier defaults are **not** editable per org. | locked | v4 Phase F |
| **D-v4-PERM-6** | Detailed permissions section is renamed **Detailed permissions**, collapsible (collapsed by default). | locked | v4 Phase E |
| **D-v4-NAV-1** | Profile nav adds **People** row **above Pets**. Admin contacts row remains (filtered People). Foster parents row remains for operational foster directory. | locked | v4 Phase B |
| **D-v4-EDIT-1** | Create organisation uses the **same template as Edit** (including branding hero). Primary buttons: **Create** / **Save**. Create shows **Cancel** (not Delete). | locked | v4 Phase A |
| **D-v4-FOSTER-2** | Foster invite for **existing** AgathaTrack users: **in-app notification only** (email deferred). New users: separate **Invitation to foster via AgathaTrack** email template (EN/FR), org-customisable under Document templates → Email templates. | locked | v4 Phase G |
| **D-v4-FOSTER-3** | Foster onboarding **timeline** on person org profile: vertical stepper with checkmark-in-disc for completed steps; org staff may **override/confirm** any step. Steps without backend data show deferred placeholder until built. | locked | v4 Phase H |
| **D-v4-BULK-1** | Bulk **Change role** from People routes to Roles & Permissions with selected people pre-loaded (same screen as single edit). | locked | v4 Phase D |

---

## How to use this log

- New decision discovered mid-implementation → add a row here **first**, then implement.
- A decision proves wrong during a phase → do not silently code around it. Update the row
  (status `tbd` → new status), note the phase/PR that revised it, and flag in that phase's
  "Open questions" section.
- Phase docs and the program contract **link to decision IDs**; they do not re-explain rationale.
