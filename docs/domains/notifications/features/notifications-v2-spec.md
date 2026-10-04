---
title: Notifications v2 — Activity & Agatha Suggestions (functional spec)
owner: Product
audience: both
status: proposed
last_updated: 2026-10-04
tags: [domain,notifications,spec,suggestions,sharing]
domain: notifications
feature_id: notifications-v2
---

# Notifications v2 — Activity & Agatha Suggestions

> **Status: proposed.** Once accepted, this spec supersedes the `care` notification kind in **D7** and the
> **All / Care / Organisation** chips in **D8**. It also extends D9–D11. It is a functional spec only. Implementation
> follows the rollout in §12, with one atomic PR per outcome.

## 1. Problem & intent

### 1.1 Problem

The notification feed today is mostly made of `care` items: health, weight and other-entry due reminders. The
same items already appear on the dashboard (**Care Actions**) and in the **Actions** tab (`/pc/events`). As a result:

- the bell badge is always lit, so users learn to ignore it;
- the events that only the inbox can tell you about get buried: someone shared a pet with you, your access
  changed, a member joined your household;
- Agatha's intelligence (`care_intelligence` recommendations) has no lasting place where it is surfaced.

### 1.2 Product principle

> **The inbox holds only what the inbox alone can tell you.**
> *Schedule* ("what must I do?") lives in Care Actions / Actions. *Inbox* ("what changed that I didn't do,
> and what does Agatha think I should know?") lives behind the bell.

**Test for any new notification type:** if the user never opened the inbox, would they miss this information
anywhere else in the app? If not, it is not an inbox notification.

### 1.3 Inspiration (patterns adopted)

| Pattern | Seen in | Applied here |
|---|---|---|
| Activity feed separated from agenda | GitHub, Linear, Slack Activity | Care reminders leave the inbox (§4) |
| Inline accept/decline on invites | Google Drive, Slack, Figma | Actionable Activity rows (§6.3) |
| "X and 2 others…" aggregation | Instagram, GitHub, Google Photos sharing | Grouping rules (§6.4) |
| Health insight cards with "why" | Apple Health Highlights, Oura, Whoop | Suggestion cards (§7.3) |
| Dismiss + "not relevant" feedback loop | Google Discover, Spotify | Suggestion feedback (§7.5) |
| Per-category × per-channel settings matrix | iOS/Android channels, Slack, GitHub | Settings (§8) |
| Weekly digest instead of drip pushes | Duolingo, Strava, Oura weekly report | Suggestions digest (§9.3) |
| Calm badge (dot vs count) | iOS Focus-era guidance, Linear | Badge rules (§5.4) |
| Non-mutable security notices | Banking apps, Google account | Mandatory events (§8.3) |

### 1.4 Goals / non-goals

**Goals**
- G1. Reduce inbox volume by removing duplicated care items. Target: at least 70% fewer inbox rows per active user per week.
- G2. Make relationship and access changes impossible to miss, and actionable in one tap.
- G3. Give Agatha Suggestions a trustworthy, low-noise home that users can explain and control.
- G4. Let users choose, per category, between inbox, push, email or off.

**Non-goals**
- Changing *how* care reminders are scheduled or delivered as push/local notifications (only their inbox row goes).
- Building a chat or messaging system.
- Org-admin notification product surface (still deferred, D-v3-NOTIF-1). Org items keep their current behaviour
  under `administrative`.
- Medical diagnosis. Suggestions are advisory (§7.7).

## 2. Glossary

| Term | Meaning |
|---|---|
| **Inbox** | The list behind the global bell (panel on wide screens, screen on mobile). |
| **Activity** | Inbox tab for relationship/access/administrative events caused by *someone else* or by the system on someone's behalf. |
| **For you** | Inbox tab for Agatha Suggestions. |
| **Suggestion** | A server-generated, pet-scoped recommendation with an explanation and one primary action. |
| **Actor** | The person whose action caused the notification (inviter, sharer, remover…). |
| **Subject pet** | The pet the notification is about (nullable for household/account-level items). |
| **Needs response** | An Activity item that references an open object awaiting the recipient's decision (D9 "unresolved"). |
| **Care reminder** | Due/overdue reminder for a health/weight/other entry. Push/local only after v2. |

## 3. Notification taxonomy

### 3.1 Kinds (replaces D7 `care | administrative`)

| `kind` (wire) | Tab | Description |
|---|---|---|
| `relationship` | Activity | People & access changes on pets, households, account. |
| `administrative` | Activity | Existing org/foster workflow items (unchanged semantics, D9–D11). |
| `suggestion` | For you | Agatha Suggestions. |
| `care` | — | **Retired for new rows.** Existing rows are archived (§11). The wire value is still parsed for backward compatibility and never shown. |

`scope` (`pet_care` / `organization`) and `priority` (`normal` / `urgent`) remain orthogonal and unchanged.

### 3.2 Relationship event catalogue

Each event has a stable `type` code. Copy is EN. FR equivalents follow `docs/design/copy-tone.md`.

| # | `type` | Recipient(s) | Trigger | Example copy | Needs response | Mandatory (§8.3) |
|---|---|---|---|---|---|---|
| R1 | `share.invite_received` | Invitee | Someone invites you to a pet | **Marie** invited you to care for **Luna** (Full access) | Yes | No |
| R2 | `share.invite_accepted` | Inviter | Invitee accepts | **Paul** accepted your invite to **Luna** | No | No |
| R3 | `share.invite_declined` | Inviter | Invitee declines | **Paul** declined your invite to **Luna** | No | No |
| R4 | `share.invite_expired` | Inviter | Invite expires unanswered | Your invite to **Paul** for **Luna** expired | No (offers *Resend*) | No |
| R5 | `share.access_changed` | Affected member | Role changed (e.g. Full → Can log care) | **Marie** changed your access to **Luna** to *Can log care* | No | **Yes** |
| R6 | `share.access_removed` | Removed member | Removed from a pet | You no longer have access to **Luna** | No | **Yes** |
| R7 | `share.member_left` | Pet owner + Full-access members | Member leaves voluntarily | **Paul** stopped caring for **Luna** | No | No |
| R8 | `household.invite_received` | Invitee | Household invite | **Marie** invited you to the **Dupont household** | Yes | No |
| R9 | `household.member_joined` | Household members | Join accepted | **Paul** joined the **Dupont household** | No | No |
| R10 | `household.member_left` | Household members | Leave / removal | **Paul** left the **Dupont household** | No | Yes for the removed person |
| R11 | `household.pet_added` | Household members | Pet added to household | **Luna** was added to the **Dupont household** | No | No |
| R12 | `household.pet_removed` | Household members | Pet removed (D22 neutral notice) | **Luna** is no longer in the **Dupont household** | No | No |
| R13 | `ownership.transfer_requested` | Proposed new owner | Transfer initiated | **Marie** wants to transfer **Luna** to you | Yes | **Yes** |
| R14 | `ownership.transfer_completed` | Previous + new owner | Transfer accepted | You are now **Luna**'s owner / **Luna** is now owned by **Paul** | No | **Yes** |
| R15 | `absence.access_granted` | Record owner (D19) | Someone else grants absence access | **Marie** gave **Paul** access to **Luna** while you're away | No | No |
| R16 | `care_assignment.assigned` | Assignee | Someone names you to look after an occurrence or period (D21) | **Marie** asked you to look after **Luna** from 12–19 Oct | No | No |

Org/foster workflow items (placements, custody, adoption, agreement withdrawal) remain `administrative`, keep their
current types, and appear in the Activity tab.

### 3.3 Suggestion catalogue (initial set)

| # | `type` | Source signal | Example headline | Primary action |
|---|---|---|---|---|
| S1 | `suggestion.missing_recurring_care` | Pet species/age profile lacks a commonly recurring item (e.g. yearly vaccine, deworming) | **Luna** has no deworming reminder. Cats usually need one every 3 months. | *Add reminder* |
| S2 | `suggestion.weight_trend` | Weight change ≥ threshold over window | **Luna**'s weight is up 8% since July | *Open weight chart* |
| S3 | `suggestion.repeated_symptom` | Same symptom logged ≥ N times in window, not linked to a health issue | You logged vomiting 3 times this week for **Rex** | *Track as health issue* |
| S4 | `suggestion.overdue_pattern` | An item is repeatedly completed late (≥ 3 of last 4) | **Rex**'s flea treatment is often late. Move it to a different day? | *Adjust schedule* |
| S5 | `suggestion.stale_record` | No weight logged in > X days for a species where it matters | No weight logged for **Luna** in 4 months | *Log weight* |
| S6 | `suggestion.care_family` | Existing `care_family_suggestion_banner` logic | Group these 3 items as a "Dental care" routine? | *Review* |
| S7 | `suggestion.share_coverage` | Owner has an upcoming absence and no carer is assigned | You're away 12–19 Oct and no one is assigned to **Luna** | *Assign someone* |

Thresholds (`N`, `X`, percentages, windows) are configuration values owned by care intelligence, not by the client.

## 4. Care reminders after v2

| ID | Requirement |
|---|---|
| FR-CR-1 | The server MUST NOT create inbox rows with `kind=care` after the v2 cut-over. |
| FR-CR-2 | Care reminders MUST continue to be delivered as push/local notifications according to existing reminder settings and D21/D25 recipient rules. |
| FR-CR-3 | Tapping a care reminder push MUST deep-link to the care item / occurrence, exactly as today. |
| FR-CR-4 | Care Actions (dashboard) and Actions (`/pc/events`) remain the single source of truth for due/overdue items. |
| FR-CR-5 | Existing `care` rows MUST be archived (not deleted) by migration and excluded from inbox lists and badge counts. |

## 5. Inbox — structure & behaviour

### 5.1 Layout

| ID | Requirement |
|---|---|
| FR-IN-1 | The inbox MUST show two tabs: **Activity** (default) and **For you**. |
| FR-IN-2 | Each tab label MUST show its own indicator: a numeric count for Activity "needs response" items, and a dot for unread suggestions (§5.4). |
| FR-IN-3 | The Activity tab MUST start with a pinned section **Needs your response** (when non-empty), followed by date groups (Today / Yesterday / This week / Earlier) using the existing date-group widget. |
| FR-IN-4 | Urgent items (D11) MUST be pinned at the very top of Activity, above Needs your response. |
| FR-IN-5 | The For you tab MUST list active suggestions grouped by pet (pet avatar + name header), newest first within each pet. |
| FR-IN-6 | The org/foster `scope` grouping label ("From: <org>") MUST still be shown on `administrative` rows. The old kind chips (All / Care / Organisation) are removed. |
| FR-IN-7 | The last selected tab SHOULD be remembered per device for the session. On a fresh launch the inbox opens on Activity, unless the user arrived from a suggestion push or digest (then For you). |
| FR-IN-8 | On wide layouts the inbox remains the right slide-over panel (D8). On compact layouts it is a full screen. Both share the same content and behaviour. |

### 5.2 Row anatomy (Activity)

| ID | Requirement |
|---|---|
| FR-AR-1 | Each row MUST show the actor avatar (or a system icon if there is no actor) with the subject-pet avatar as a small overlay badge when a pet is involved. |
| FR-AR-2 | Each row MUST show a sentence where the actor and the object (pet/household) are bold, plus a relative timestamp. An absolute date/time appears on long-press or hover. |
| FR-AR-3 | Unread rows MUST have a visible unread marker that does not rely on colour alone (dot + bold weight). |
| FR-AR-4 | Tapping a row MUST mark it read and navigate to its target (pet sharing screen, household screen, transfer screen…). If the target no longer exists or the user has lost access, show a neutral "This item is no longer available" state instead of an error. |

### 5.3 Read, resolved, archived

| ID | Requirement |
|---|---|
| FR-ST-1 | States: `unread → read`, and independently `resolved` (D9) and `archived`. |
| FR-ST-2 | Needs-response items become `resolved` automatically when the referenced object changes state (accepted, declined, cancelled, expired), whether the change happened from the inbox, another screen or another device. |
| FR-ST-3 | Resolved items leave **Needs your response** and appear in the date list with the outcome ("You accepted", "Invite cancelled by Marie"). |
| FR-ST-4 | Users can archive any row (swipe on mobile, overflow menu on web). Archived rows are hidden from the inbox and can be undone for 5 seconds via snackbar. |
| FR-ST-5 | **Mark all as read** is available per tab and MUST NOT resolve or archive anything. |
| FR-ST-6 | Rows older than 90 days are automatically archived. Unresolved needs-response items are never auto-archived while their object is still open. |

### 5.4 Badge

| ID | Requirement |
|---|---|
| FR-BG-1 | The bell badge shows a **number** equal to: unread Activity items that are needs-response or urgent. |
| FR-BG-2 | If the number is 0 but there are other unread Activity items or unread suggestions, the bell shows a **dot** with no number. |
| FR-BG-3 | The badge MUST NOT count care reminders, archived items, resolved items, or items from a scope the user can no longer see. |
| FR-BG-4 | The badge MUST update within 5 s of an inbox change in the active session (polling or push-triggered refresh), and immediately after the user's own actions. |
| FR-BG-5 | The badge count is capped visually at "9+". |

## 6. Activity — functional requirements

### 6.1 Generation

| ID | Requirement |
|---|---|
| FR-AC-1 | Each event in §3.2 MUST create exactly one row per recipient (idempotent on `type + object_id + recipient + event_version`). |
| FR-AC-2 | The actor MUST NOT receive a notification for their own action (e.g. the inviter is not told they invited). |
| FR-AC-3 | Recipients are computed at event time from the access model (`petAccess`). Someone who loses access afterwards still keeps rows they already received, but their targets fall back to FR-AR-4. |
| FR-AC-4 | Rows MUST store a snapshot of actor display name, pet name and role label, so the text stays readable if the source is later renamed or deleted. |
| FR-AC-5 | Events for a pet in an org/foster context take the scope of that context, as today. |

### 6.2 Privacy

| ID | Requirement |
|---|---|
| FR-PR-1 | A notification MUST NOT reveal information about a pet or person the recipient was never entitled to see. Example: removal notices (R6) do not include who else still has access. |
| FR-PR-2 | Email and push text for relationship events MUST include only first name + pet name, never health data. |
| FR-PR-3 | When an account is deleted, its rows are deleted. Rows held by others that name the deleted actor show "A former member". |

### 6.3 Inline actions

| ID | Requirement |
|---|---|
| FR-IA-1 | Needs-response rows (R1, R8, R13 and administrative pending items per D10) MUST show inline primary/secondary buttons (**Accept** / **Decline**) without opening another screen. |
| FR-IA-2 | Accept on a share invite MUST show what is granted (role, pet) before confirming, either in the row itself or in a bottom sheet. Ownership transfer (R13) ALWAYS requires a confirmation sheet. |
| FR-IA-3 | Decline MUST ask for confirmation via a snackbar with Undo (5 s), not a modal. |
| FR-IA-4 | While the action runs, buttons are disabled with a progress indicator. On failure, the row restores and shows an inline error with Retry. |
| FR-IA-5 | If the object was already resolved elsewhere (stale), the action MUST NOT error destructively. The row refreshes to its resolved state and shows "Already handled". |
| FR-IA-6 | R4 (invite expired) offers **Resend**. R7 offers no action. |

### 6.4 Grouping

| ID | Requirement |
|---|---|
| FR-GR-1 | Non-actionable rows of the same `type` and the same subject (pet or household) within a 24 h window MUST collapse into one row: "**Paul** and **2 others** now have access to **Luna**". |
| FR-GR-2 | A grouped row expands on tap to list each member event, each with its own timestamp. |
| FR-GR-3 | Needs-response, mandatory and urgent items are NEVER grouped. |
| FR-GR-4 | A grouped row counts as one unread item and is read once expanded or opened. |

## 7. For you — Agatha Suggestions

### 7.1 Generation (server-side)

| ID | Requirement |
|---|---|
| FR-SG-1 | Suggestions MUST be generated server-side by a scheduled job (at least daily) and on relevant data changes (e.g. new weight entry). They are persisted as `kind=suggestion` rows. |
| FR-SG-2 | Each suggestion has: `type`, `pet_id`, `headline`, `rationale` (one sentence), `evidence` (structured: data points and window), `primary_action` (deep link + label), `confidence` (0–1), `expires_at`, `dedupe_key`. |
| FR-SG-3 | Only suggestions with confidence ≥ the configured threshold (default 0.7) are created. |
| FR-SG-4 | Recipient: pet owner and Full-access members. Can-log-care members only get S7-type items addressed to them. Org/foster pets follow scope rules. |
| FR-SG-5 | A `dedupe_key` (e.g. `weight_trend:<pet>:<window>`) MUST prevent the same suggestion from being active twice. A refreshed signal updates the existing row rather than creating a new one. |
| FR-SG-6 | The client-side `care_recommendations_provider` becomes a consumer of the server output. No suggestion is computed only on the client. |

### 7.2 Rate limiting & lifetime

| ID | Requirement |
|---|---|
| FR-RL-1 | At most **3 new suggestions per pet per rolling 7 days**, and at most **5 per user per rolling 7 days** across pets. Selection is by `confidence × type priority`. |
| FR-RL-2 | At most **10 active** (not dismissed/expired/completed) suggestions per user at any time. |
| FR-RL-3 | Suggestions auto-expire after **14 days** by default (configurable per type). Expired suggestions disappear without notifying anyone. |
| FR-RL-4 | A suggestion whose underlying condition no longer holds (e.g. the reminder was added) MUST be auto-completed and removed within one generation cycle, or immediately when the user's own action resolves it. |

### 7.3 Card anatomy

| ID | Requirement |
|---|---|
| FR-SC-1 | A card shows: the pet avatar, a headline (≤ 80 chars), a rationale ("Based on 6 weight entries since June"), one primary action button, and an overflow with **Dismiss**, **Not relevant** and **Why am I seeing this?**. |
| FR-SC-2 | **Why am I seeing this?** opens a sheet that lists the evidence (data points, dates, threshold used) in plain language and links to the source records. |
| FR-SC-3 | Health-adjacent suggestions (S2, S3) MUST include the line "Agatha isn't a vet. If you're worried, talk to your vet." |
| FR-SC-4 | The primary action deep-links into the existing flow, pre-filled where possible (e.g. new reminder form pre-filled with type and frequency). Completing that flow marks the suggestion `completed`. |

### 7.4 States

`new → seen → (acted | dismissed | not_relevant | expired | completed)`. A card is `seen` once it has been visible
for at least 1 s. Only `new` counts as unread.

### 7.5 Feedback loop

| ID | Requirement |
|---|---|
| FR-FB-1 | **Dismiss** hides this suggestion only. The same `dedupe_key` MUST NOT reappear for 30 days. |
| FR-FB-2 | **Not relevant** hides it and suppresses that `type` for that pet for 90 days. An optional one-tap reason can be recorded ("Already handled elsewhere", "Doesn't apply to my pet", "Too frequent"). |
| FR-FB-3 | Three "Not relevant" responses for the same `type` across pets within 90 days MUST suppress that type account-wide, and the settings screen MUST show it as off (§8). |
| FR-FB-4 | Feedback events are stored to measure per-type acceptance and precision (§10). |

### 7.6 Empty & onboarding states

| ID | Requirement |
|---|---|
| FR-EM-1 | For you empty state: "No suggestions right now. Agatha will let you know when something's worth a look." plus a link to settings. |
| FR-EM-2 | Activity empty state: "Nothing new. When someone shares a pet or joins your household, you'll see it here." |
| FR-EM-3 | The first time a user opens the inbox after v2, a one-time dismissible explainer says: "Reminders now live in Actions. Your inbox is for people updates and Agatha's suggestions." It links to Actions. |

### 7.7 Safety & tone

| ID | Requirement |
|---|---|
| FR-SF-1 | Suggestions MUST use advisory language ("consider", "you may want to") and never diagnose or prescribe dosages. |
| FR-SF-2 | Suggestions MUST NOT be generated for deceased/archived pets or for pets the user can only view. |
| FR-SF-3 | Copy follows `docs/design/copy-tone.md` and is available in EN and FR at launch. |

## 8. Settings

### 8.1 Matrix

The notification settings screen shows a matrix of **category × channel**:

| Category | In-app inbox | Push | Email | Default |
|---|---|---|---|---|
| Invites & requests (R1, R8, R13) | always | on | on | — |
| Access & membership changes (R2–R7, R9–R12, R14–R16) | always | on | off | — |
| Organisation & foster (administrative) | always | on | per existing prefs | — |
| Agatha Suggestions | on | **weekly digest** (off / weekly digest / instant) | off | inbox + weekly digest |
| Care reminders | — (not in inbox) | existing reminder settings | existing | unchanged |

### 8.2 Requirements

| ID | Requirement |
|---|---|
| FR-SE-1 | Settings MUST persist server-side in `notification_preferences` and apply on all devices. |
| FR-SE-2 | Turning **Agatha Suggestions → In-app** off stops generation for that user (not only display) and hides existing active suggestions. The For you tab then shows an "Agatha Suggestions are off" state with a toggle. |
| FR-SE-3 | Per-suggestion-type toggles are available under Agatha Suggestions (S1–S7), including those auto-suppressed by FR-FB-3. |
| FR-SE-4 | If the OS push permission is denied, push toggles show a "Push is off for Agatha in your device settings" hint with a link to the OS settings, rather than appearing enabled. |

### 8.3 Mandatory notifications

| ID | Requirement |
|---|---|
| FR-MD-1 | Items marked **Mandatory** in §3.2 always create an inbox row and always send an email, whatever the preferences. Push still follows the user's preference. |
| FR-MD-2 | The settings screen shows mandatory items as locked with the explanation "Sent for your account's security". |

## 9. Delivery channels

### 9.1 Push

| ID | Requirement |
|---|---|
| FR-PU-1 | Relationship pushes are sent at most once per event, and grouped per FR-GR-1 if several arrive within 2 minutes ("Paul and 2 others joined…"). |
| FR-PU-2 | Quiet hours (if defined by the user or OS focus) MUST be respected for non-urgent, non-mandatory items. These are delivered at the end of quiet hours. |
| FR-PU-3 | Tapping a push opens the specific row's target and marks the row read. |

### 9.2 Email

| ID | Requirement |
|---|---|
| FR-EML-1 | Emails contain one call-to-action linking into the app, plus an unsubscribe link for that category (except mandatory items). |
| FR-EML-2 | Invite emails MUST also work for invitees without an account (sign-up then land on the invite). This is existing behaviour and must stay the same. |

### 9.3 Weekly suggestions digest

| ID | Requirement |
|---|---|
| FR-DG-1 | Sent at most once per week, on the user's configured day (default Monday) at 09:00 local time. |
| FR-DG-2 | Sent only if there is at least one suggestion that is new since the last digest. Otherwise nothing is sent. |
| FR-DG-3 | Content: "Agatha has N suggestions for Luna and Rex" (push), or a short list of headlines (email). Opening it lands on the For you tab. |
| FR-DG-4 | **Instant** mode sends one push per new suggestion, still subject to FR-RL-1. |

## 10. Non-functional requirements

| ID | Requirement |
|---|---|
| NFR-1 Performance | Inbox first page (30 rows) p95 < 300 ms server time. The badge endpoint p95 < 100 ms. |
| NFR-2 Pagination | Cursor pagination per tab. Scrolling loads the next page without jumping. |
| NFR-3 Offline | The last fetched inbox is shown from cache when offline, with an "Offline, showing last update" banner. Inline actions are disabled offline. |
| NFR-4 Accessibility | WCAG 2.2 AA: rows and cards are single semantic elements with a full spoken label ("Unread. Marie invited you to care for Luna, Full access, 2 hours ago. Actions available."). Inline buttons are reachable in focus order. Target size ≥ 24×24 CSS px (44 recommended). Unread state is not conveyed by colour alone. Tab indicators are announced ("Activity, 2 need your response"). Swipe actions have a non-gesture alternative. See `.cursor/rules/accessibility.mdc`. |
| NFR-5 i18n | All strings EN/FR, with plural-aware grouping text. Dates are formatted per locale. Calendar dates follow `docs/architecture/calendar-dates.md`. |
| NFR-6 Security | All list/action endpoints authorise on the recipient. Inline actions re-check access server-side (never trust the row). Suggestion evidence is only returned to users who still have access to the pet. |
| NFR-7 Observability | Metrics: rows created per kind/type, inbox opens, inline action success/failure, suggestion funnel (created → seen → acted / dismissed / not relevant / expired), digest sends and opens. |
| NFR-8 Data retention | Rows are archived at 90 days and hard-deleted at 365 days. Suggestion feedback is kept 365 days for quality measurement. |
| NFR-9 Modularity | New UI/server modules respect the 500-line limit (`node scripts/check_file_size.js`). |

### 10.1 Success metrics

- Inbox rows per weekly-active user: **−70%** vs baseline within 4 weeks of launch.
- Median time to respond to a share invite: **−50%**.
- Suggestion acted-on rate **≥ 25%**. "Not relevant" rate **≤ 15%** per type. Any type above 30% is reviewed or disabled.
- Push opt-out rate does not increase vs baseline.

## 11. Migration & compatibility

| ID | Requirement |
|---|---|
| FR-MG-1 | A migration adds `kind` values `relationship` and `suggestion`, plus the suggestion fields (§7.1) in a structured column or companion table. UUIDs are generated in code (no `gen_random_uuid()`). |
| FR-MG-2 | Existing `care` rows are set to `archived` (kept for reports per `pet_report_notifications_section`). They do not appear in the inbox or the badge. |
| FR-MG-3 | Existing share/household/transfer rows currently stored as `administrative` are re-classified to `relationship` where they match a §3.2 type. Unmatched rows stay `administrative`. |
| FR-MG-4 | Older clients receiving unknown `kind` values MUST NOT crash. The current client parser defaults unknown values to `care`, so the server MUST omit `relationship`/`suggestion` rows for clients below the minimum version, or the client parser MUST be updated first (ship the parser in PR 1). |
| FR-MG-5 | Decision docs updated: D7 (kinds), D8 (tabs replace chips) are marked superseded with a link here. |

## 12. Rollout (atomic PRs)

| PR | Outcome | Verifiable by |
|---|---|---|
| 1 | Stop creating `care` inbox rows. Archive existing ones. Client parses new kinds safely. | AC-CR-*, AC-MG-* |
| 2 | Two-tab inbox (Activity / For you), empty states, explainer, badge rules | AC-IN-*, AC-BG-* |
| 3 | Relationship catalogue R1–R16 generated server-side, with privacy rules | AC-AC-*, AC-PR-* |
| 4 | Inline actions + Needs your response + grouping | AC-IA-*, AC-GR-* |
| 5 | Server-generated suggestions S1–S7, rate limits, cards, feedback | AC-SG-*, AC-FB-* |
| 6 | Settings matrix, mandatory items, push/email/digest | AC-SE-*, AC-DG-* |

Each PR extends `notifications.feature` (BDD) and `notifications.spec.ts` (E2E) for the criteria it ships.

## 13. Acceptance criteria

Written in Given/When/Then form so they can be turned into BDD scenarios with minimal rewording.

### 13.1 Care reminders removed from inbox (AC-CR)

- **AC-CR-1** — Given a pet with a vaccine due today, when the reminder job runs, then a push/local reminder is delivered **and** no inbox row is created **and** the bell badge does not change.
- **AC-CR-2** — Given the same pet, when I open Care Actions and Actions, then the due item is listed there exactly as before v2.
- **AC-CR-3** — Given I tap the care reminder push, then I land on that occurrence's detail screen.
- **AC-CR-4** — Given I had 12 unread `care` rows before migration, when the migration runs, then those rows are archived, they do not appear in either tab, and the badge does not count them.
- **AC-CR-5** — Given a pet report is generated after migration, then its notifications section still includes historical care rows (archived rows remain reportable).

### 13.2 Inbox structure (AC-IN)

- **AC-IN-1** — Given I open the inbox, then I see exactly two tabs, **Activity** and **For you**, Activity is selected, and the All / Care / Organisation chips are gone.
- **AC-IN-2** — Given I have 2 unanswered invites and 3 older read items, when I open Activity, then **Needs your response** appears first with the 2 invites, followed by date groups containing the 3 items.
- **AC-IN-3** — Given I have an urgent agreement-withdrawal item and an invite, then the urgent item is above **Needs your response**.
- **AC-IN-4** — Given I have no pending items, then the **Needs your response** header is not rendered.
- **AC-IN-5** — Given I have suggestions for Luna and Rex, when I open For you, then cards are grouped under a Luna header and a Rex header, newest first within each.
- **AC-IN-6** — Given I am a foster with an org item, then the row shows the "From: <org name>" label.
- **AC-IN-7** — Given I open the app from a suggestions digest push, then the inbox opens on For you.
- **AC-IN-8** — Given a wide (≥ desktop breakpoint) layout, then the inbox opens as the right slide-over. On a compact layout it opens full-screen with identical content.
- **AC-IN-9** — Given it is my first inbox open after v2, then the explainer is shown once. Once I dismiss it, it never appears again on any device.
- **AC-IN-10** — Given both tabs are empty, then each shows its specific empty-state copy (FR-EM-1/2).

### 13.3 Badge (AC-BG)

- **AC-BG-1** — Given 2 unread pending invites and 1 unread "member joined", then the badge shows **2**.
- **AC-BG-2** — Given 0 pending items, 1 unread "member joined" and 1 new suggestion, then the badge shows a **dot** without a number.
- **AC-BG-3** — Given everything is read, then no badge is shown.
- **AC-BG-4** — Given I accept an invite inline, then the badge decrements immediately without a reload.
- **AC-BG-5** — Given the invite is accepted on another device, then within 5 s the badge on this device decrements.
- **AC-BG-6** — Given 14 pending items, then the badge shows **9+**.
- **AC-BG-7** — Given a due care reminder exists, then the badge is unaffected.

### 13.4 Activity generation (AC-AC)

- **AC-AC-1** — Given Marie invites Paul to Luna with Full access, then Paul gets exactly one R1 row reading "Marie invited you to care for Luna (Full access)", and Marie gets none.
- **AC-AC-2** — Given Paul accepts, then Marie gets R2, Paul's R1 becomes resolved "You accepted", and the Full-access members of Luna get no R1/R2 duplicates.
- **AC-AC-3** — Given Paul declines, then Marie gets R3 and Paul's R1 shows "You declined".
- **AC-AC-4** — Given an invite reaches its expiry unanswered, then Marie gets R4 with a **Resend** action, and Paul's R1 shows "Invite expired" without Accept/Decline.
- **AC-AC-5** — Given Marie changes Paul's role to Can log care, then Paul gets R5 naming the new role.
- **AC-AC-6** — Given Marie removes Paul from Luna, then Paul gets R6 "You no longer have access to Luna". The row does not list remaining members, and tapping it shows the "no longer available" state, not an error.
- **AC-AC-7** — Given Paul leaves Luna himself, then the owner and Full-access members get R7, and Paul gets nothing.
- **AC-AC-8** — Given a pet is removed from a household, then members get the neutral R12 notice (D22 wording).
- **AC-AC-9** — Given Marie initiates an ownership transfer of Luna to Paul, then Paul gets R13 with Accept/Decline. On acceptance, both get R14.
- **AC-AC-10** — Given Marie grants Paul absence access on Jo's pet, then Jo (record owner) gets R15.
- **AC-AC-11** — Given the same event is processed twice (retry), then only one row exists per recipient (idempotency).
- **AC-AC-12** — Given Luna is renamed "Lulu" after R1 was created, then R1 still reads coherently (snapshot name), and its target opens the renamed pet.
- **AC-AC-13** — Given Marie deletes her account, then rows mentioning her show "A former member".

### 13.5 Privacy & security (AC-PR)

- **AC-PR-1** — Given I request another user's notification by id, then the API returns 404 and leaks nothing.
- **AC-PR-2** — Given I lost access to Luna, when I try an inline action on an old Luna row, then the server rejects it and the row shows "no longer available".
- **AC-PR-3** — Given any relationship push or email, then its text contains no health data (only names, pet name, role).
- **AC-PR-4** — Given I lost access to Luna, when I open an old Luna suggestion, then its evidence is not returned.

### 13.6 Inline actions (AC-IA)

- **AC-IA-1** — Given an R1 row, then **Accept** and **Decline** are visible in the row without opening it.
- **AC-IA-2** — When I tap Accept on R1, then I see the granted role and pet before confirming. On confirm, I get access to Luna and the row moves to the date list as "You accepted".
- **AC-IA-3** — When I tap Decline, then a snackbar with **Undo** shows for 5 s. If I tap Undo, the invite returns to pending and the inviter is not notified.
- **AC-IA-4** — When I tap Accept on R13 (ownership), then a confirmation sheet is always shown before anything happens.
- **AC-IA-5** — Given the network fails during Accept, then the buttons re-enable, an inline error with **Retry** is shown, and no state changes.
- **AC-IA-6** — Given the inviter cancelled the invite after my inbox loaded, when I tap Accept, then the row refreshes to "Invite cancelled by Marie" with an "Already handled" note and no error dialog.
- **AC-IA-7** — Given a pending foster placement (D10 administrative), then it appears in **Needs your response** with inline actions, following the same rules.
- **AC-IA-8** — Given a keyboard-only user, then Tab moves through row → Accept → Decline in order, and Enter/Space activates them.

### 13.7 Grouping (AC-GR)

- **AC-GR-1** — Given Paul, Léa and Sam each accept invites to Luna within 24 h, then Marie sees one row "Paul and 2 others now have access to Luna".
- **AC-GR-2** — When Marie expands it, then 3 entries with individual timestamps are shown, and the group becomes read.
- **AC-GR-3** — Given 2 pending invites for the same pet, then they are shown as 2 separate rows (actionable items are never grouped).
- **AC-GR-4** — Given events 25 h apart, then they are not grouped.
- **AC-GR-5** — Given grouping occurs, then the screen-reader label announces the full sentence with the count ("Paul and 2 others…").

### 13.8 Read / resolved / archive (AC-ST)

- **AC-ST-1** — When I tap a row, then it is marked read and I navigate to its target.
- **AC-ST-2** — When I tap **Mark all as read** on Activity, then all Activity rows become read, pending items stay in **Needs your response** (still unresolved), and For you is unaffected.
- **AC-ST-3** — When I swipe a row to archive, then it disappears with a 5 s **Undo** snackbar. The overflow menu offers the same action on web.
- **AC-ST-4** — Given a non-pending row older than 90 days, then it is no longer listed.
- **AC-ST-5** — Given an unanswered invite older than 90 days whose object is still open, then it is still listed.

### 13.9 Suggestions generation (AC-SG)

- **AC-SG-1** — Given an adult cat with no deworming item, when the daily job runs, then one S1 suggestion is created for its owner and Full-access members, and not for Can-log-care members.
- **AC-SG-2** — Given Luna's weight increased 8% over 3 months above a 5% threshold, then an S2 card appears with rationale "Based on N weight entries since <month>".
- **AC-SG-3** — Given vomiting is logged 3 times in 7 days without a linked health issue, then S3 appears. Its primary action opens the health-issue form pre-linked to those entries.
- **AC-SG-4** — Given a signal with confidence 0.6 (threshold 0.7), then no suggestion is created.
- **AC-SG-5** — Given an S2 already active for Luna, when the job runs again, then no duplicate is created and the existing card's evidence is updated.
- **AC-SG-6** — Given 5 eligible suggestions for one pet in a week, then at most 3 are created, chosen by highest confidence × priority.
- **AC-SG-7** — Given 4 pets each with 3 eligible suggestions, then at most 5 new suggestions are created for that user in the week.
- **AC-SG-8** — Given a suggestion is 14 days old and untouched, then it disappears from For you without any notification.
- **AC-SG-9** — Given I add the deworming reminder from any screen, then the S1 card is removed (completed) immediately on refresh.
- **AC-SG-10** — When I tap S1's **Add reminder**, then the reminder form opens pre-filled with type and frequency. Saving marks the suggestion completed.
- **AC-SG-11** — Given a pet marked deceased/archived, then no suggestions are generated for it, and its active ones are removed.
- **AC-SG-12** — Given S2 or S3, then the card shows the "Agatha isn't a vet…" line.
- **AC-SG-13** — When I tap **Why am I seeing this?**, then a sheet lists the data points, dates and threshold in plain language, with links to the source entries.
- **AC-SG-14** — Given any suggestion copy, then it contains no diagnosis or dosage wording (copy review checklist, EN and FR).

### 13.10 Suggestion feedback (AC-FB)

- **AC-FB-1** — When I **Dismiss** an S5 for Luna, then it disappears, and the same suggestion does not reappear for 30 days even if the condition persists.
- **AC-FB-2** — When I mark S4 **Not relevant** for Rex, then no S4 is created for Rex for 90 days, but S4 for Luna can still appear.
- **AC-FB-3** — Given I mark S4 Not relevant for 3 different pets within 90 days, then S4 is suppressed account-wide, and settings show S4 turned off.
- **AC-FB-4** — When I choose an optional reason, then it is recorded. Skipping the reason still records Not relevant.
- **AC-FB-5** — Given a card is visible for at least 1 s, then its state becomes seen and it no longer counts as unread.

### 13.11 Settings (AC-SE)

- **AC-SE-1** — When I open notification settings, then I see the category × channel matrix with the defaults in §8.1.
- **AC-SE-2** — Given I turn Agatha Suggestions → In-app off, then active suggestions disappear, no new ones are generated, and For you shows the "Suggestions are off" state with a toggle.
- **AC-SE-3** — Given I turn off Access & membership push, then R7 creates an inbox row but no push.
- **AC-SE-4** — Given I turned off all relationship email, when Marie removes me from Luna (R6, mandatory), then I still receive the email and the inbox row.
- **AC-SE-5** — Given mandatory items, then their toggles appear locked with "Sent for your account's security".
- **AC-SE-6** — Given OS push permission is denied, then push toggles show the device-settings hint instead of an enabled state.
- **AC-SE-7** — Given I change a setting on web, then my phone reflects it on the next settings load.
- **AC-SE-8** — Given Care reminders, then the matrix shows no in-app inbox option, and a link points to the existing reminder settings.

### 13.12 Push, email & digest (AC-DG)

- **AC-DG-1** — Given the default digest setting and 2 new suggestions this week, when Monday 09:00 local comes, then I receive one push "Agatha has 2 suggestions for Luna and Rex". Opening it lands on For you.
- **AC-DG-2** — Given no new suggestions since the last digest, then no digest is sent.
- **AC-DG-3** — Given Instant mode, then each new suggestion sends one push, and the weekly caps still apply.
- **AC-DG-4** — Given 3 people join my household within 2 minutes, then I receive a single push "Paul and 2 others joined the Dupont household".
- **AC-DG-5** — Given quiet hours 22:00–07:00, when R9 happens at 23:00, then the push is delivered at 07:00. If R6 (mandatory) happens at 23:00, then the email is sent immediately and the push follows my preference and quiet hours.
- **AC-DG-6** — Given any non-mandatory email, then it contains a working one-click unsubscribe for that category.
- **AC-DG-7** — Given an invitee without an account, when they follow the invite email, then after sign-up they land on the pending invite (regression of existing behaviour).

### 13.13 Non-functional (AC-NF)

- **AC-NF-1** — With 1,000 rows for one user, the first page p95 is < 300 ms and the badge p95 is < 100 ms in the perf test.
- **AC-NF-2** — Scrolling past 30 rows loads the next page with no duplicates or gaps.
- **AC-NF-3** — Offline, the cached inbox is shown with the offline banner, and inline actions are disabled with an explanatory tooltip.
- **AC-NF-4** — A screen-reader pass (TalkBack, VoiceOver, NVDA on web) announces the tab indicators, full row labels including the unread state, and inline actions. No information is conveyed by colour alone. All targets are ≥ 24×24 px.
- **AC-NF-5** — FR locale: all strings are translated, the grouping plurals are correct ("Paul et 2 autres…"), and dates use FR formats.
- **AC-NF-6** — Metrics listed in NFR-7 are emitted and visible in the observability dashboard in UAT.
- **AC-NF-7** — `node scripts/check_file_size.js` passes, and the BDD gate (`check_bdd_coverage.js`) does not regress.

### 13.14 Migration (AC-MG)

- **AC-MG-1** — After migration, `care` rows are archived and counted 0 in the badge, and the row count is unchanged (nothing deleted).
- **AC-MG-2** — Pre-existing share/household/transfer rows show in Activity with the `relationship` treatment.
- **AC-MG-3** — A client at the previous release receives no unknown kinds (or parses them safely) and does not crash.
- **AC-MG-4** — The migration is reversible: `migrate down` restores the previous kinds and states.
- **AC-MG-5** — `notification-decisions.md` marks D7/D8 as superseded and links to this spec.

## 14. Open questions

1. Expiry windows for R1/R8 invites (currently implicit). Proposal: 14 days, with a reminder on day 7 to the invitee only.
2. Should S7 (no carer assigned during an absence) also be sent to household members, or only the owner?
3. Should the weekly digest also be available by email by default for users who have never enabled push?
4. Is the 90-day archive acceptable for org/foster audit needs, or must `administrative` rows be retained longer?
