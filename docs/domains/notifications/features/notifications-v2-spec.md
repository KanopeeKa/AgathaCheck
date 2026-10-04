---
title: Notifications v2 — Activity & Agatha Suggestions (functional spec)
owner: Product
audience: both
status: proposed (rev 2.2)
last_updated: 2026-10-04
tags: [domain,notifications,spec,suggestions,sharing]
domain: notifications
feature_id: notifications-v2
---

# Notifications v2 — Activity & Agatha Suggestions

> **Status: proposed, rev 2.2** (adds account security and subscription, §3.5). Moves to `accepted` only once the documentation checklist (AC-MG-5) is merged. Functional spec only. Implementation follows the rollout in §12, with one atomic PR
> per outcome. Rev 2 incorporates the design review; the changes are summarised in §15. Once accepted, the decisions in
> §0 take effect.

## 0. Decisions this spec supersedes or adds

Decision IDs **D12–D16** are already taken (roles and permissions), so new decisions here use the **N** prefix.

| Decision | Change |
|---|---|
| **D7** (kinds) | **Superseded.** Kinds become `relationship \| administrative \| suggestion`. `care` is retired from the inbox (§3.1, §4). |
| **D8** (bell + chips) | **Superseded in part.** One bell and the slide-over panel stay. The All / Care / Organisation chips are replaced by the **Activity / For you** tabs. The combined unread badge is replaced by the calm badge (§5.4). |
| **D9** (resolved) | **Extended.** Resolved state applies to `administrative` **and** `relationship` items that reference an open object. It is still derived from the object, never a manual dismiss. |
| **D10** (pending inboxes) | **Amended.** Pending shares and household invites move from `administrative` to `relationship`. Foster, adoption and custody pending items stay `administrative`. All of them appear in **Needs your response**, with inline actions (§6.3) instead of a deep link. |
| **D11** (urgent) | **Unchanged.** Pinned at the top of Activity. |
| **N1** | Inbox principle: only what the inbox alone can tell you (§1.2). |
| **N2** | Grouping is a read-model concern. Events are stored one per recipient (§6.4.1). |
| **N3** | Wire `type` codes stay camelCase. No rename; `kind` is reassigned through the type→kind map (§3.4). |
| **N4** | Suggestions are generated on the server only. Pet-profile suggestion cards read the same API from PR5 (§7.1). |
| **N5** | Inbox retention (archive/delete) is a UX concern. Compliance evidence lives in `audit_events` and reports, never only in the inbox (§10). |
| **N6** | Invites expire after 14 days. The invitee gets a single reminder on day 7 (R18). |
| **N7** | The S7 (absence coverage) suggestion goes to the record owner only. |
| **N8** | The weekly digest by email is offered (and on by default) only to users with no push-capable device. |
| **N9** | The inbox is not an audit log. A 90-day inbox archive is accepted for every kind. |
| **N10** | New kind `account` covers account security and subscription. It appears in the Activity tab, under its own "Account" section label. |
| **N11** | Security notices tell the user what happened and offer **"This was me" / "Secure my account"**. They never contain a sign-in link or a code (anti-phishing). |
| **N12** | Subscription notices only cover **what the app store or billing provider doesn't already tell the user**: entitlement changes and payment problems that affect Agatha. No receipts. The design is independent of the billing provider (RevenueCat today, possibly an EU provider later). |
| **N13** | "New device" detection stores only a coarse device label (OS + browser/app) and the first-seen time, with no IP and no location. Location is deferred pending a DPIA. |

Accepting this spec includes the documentation checklist in AC-MG-5.

## 0.1 Traceability to the original request

The brief: *stop notifications duplicating events, and refocus them on (a) account notifications, meaning relationship
changes such as adding people or sharing a pet, and (b) Agatha Suggestions.*

| Brief | Where it is met | Tier |
|---|---|---|
| Stop duplicating events | §4 (care reminders leave the inbox), FR-CR-1..5 | **Core** |
| Relationships: adding people, sharing a pet | R1–R3, R5–R12 (§3.2), Activity tab, inline accept/decline | **Core** |
| Agatha Suggestions | §7, For you tab, S1–S7 | **Core** (S7 → owner only) |
| Account notifications: security & subscription | §3.5, A1–A11 | **Core** for security (A1–A6); subscription (A7–A11) is core but **gated on the billing-provider decision** |
| Kept, not new: org/foster workflow items | `administrative` stays in Activity, unchanged. Removing it would drop actionable pending items (D10). | Preserved |
| Kept, not new: ownership transfer, memorial | R14, R17. These already exist today as `general` notices and are reclassified, not invented. | Preserved |
| Added for best-in-class UX (not in the brief) | Grouping (§6.4), weekly digest + email (§9.3), invite expiry/reminder (R4, R18), care assignment (R16, which depends on People D21), settings matrix beyond on/off | **Enhancement** |

**Scope rule.** PR1–PR3 and PR5 deliver the brief. The enhancements are specified so they don't need redesign later,
but they ship in PR4/PR6 and can be cut or deferred **without affecting the core outcome**. Anything not traceable to
this table is out of scope.

Account-level events (security and subscription) are **in scope since rev 2.2** (§3.5).

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
| `account` | Activity ("Account" label) | Account security and subscription (§3.5, N10). |
| `care` | — | **Retired for new rows.** Existing rows are archived (§11). The wire value is still parsed for backward compatibility and never shown. |

`scope` (`pet_care` / `organization`) and `priority` (`normal` / `urgent`) remain orthogonal and unchanged.

### 3.2 Relationship event catalogue

Each event has a stable `type` code. Copy is EN. FR equivalents follow `docs/design/copy-tone.md`.

| # | `type` | Recipient(s) | Trigger | Example copy | Needs response | Mandatory (§8.3) |
|---|---|---|---|---|---|---|
| R1 | `shareInviteReceived` | Invitee | Someone invites you to a pet | **Marie** invited you to care for **Luna** (Full access) | Yes | No |
| R2 | `shareInviteAccepted` | Inviter | Invitee accepts | **Paul** accepted your invite to **Luna** | No | No |
| R3 | `shareInviteDeclined` | Inviter | Invitee declines | **Paul** declined your invite to **Luna** | No | No |
| R4 | `shareInviteExpired` (new) | Inviter | Invite expires unanswered | Your invite to **Paul** for **Luna** expired | No (offers *Resend*) | No |
| R5 | `shareAccessChanged` (new) | Affected member | Role changed (e.g. Full → Can log care) | **Marie** changed your access to **Luna** to *Can log care* | No | **Yes** |
| R6 | `shareAccessRemoved` (new) | Removed member | Removed from a pet | You no longer have access to **Luna** | No | **Yes** |
| R7 | `shareMemberLeft` (new) | Pet owner + Full-access members | Member leaves voluntarily | **Paul** stopped caring for **Luna** | No | No |
| R8 | `householdInviteReceived` | Invitee | Household invite | **Marie** invited you to the **Dupont household** | Yes | No |
| R9 | `householdMemberJoined` (new) | Household members | Join accepted | **Paul** joined the **Dupont household** | No | No |
| R10 | `householdMemberLeft` (new) | Household members | Leave / removal | **Paul** left the **Dupont household** | No | Yes for the removed person |
| R11 | `householdPetAdded` (new) | Household members | Pet added to household | **Luna** was added to the **Dupont household** | No | No |
| R12 | `householdPetRemoved` (new) | Household members | Pet removed (D22 neutral notice) | **Luna** is no longer in the **Dupont household** | No | No |
| R13 | `ownershipTransferRequested` (future) | Proposed new owner | Transfer initiated | **Marie** wants to transfer **Luna** to you | Yes | **Yes** |
| R14 | `ownershipTransferCompleted` (new; today `general`) | Previous + new owner | Transfer accepted | You are now **Luna**'s owner / **Luna** is now owned by **Paul** | No | **Yes** |
| R15 | `absenceGuestGranted` | Record owner (D19) | Someone else grants absence access | **Marie** gave **Paul** access to **Luna** while you're away | No | No |
| R16 | `careAssignmentAssigned` (new) | Assignee | Someone names you to look after an occurrence or period (D21) | **Marie** asked you to look after **Luna** from 12–19 Oct | No | No |
| R17 | `petPassedAway` (new; today `general`) | Everyone with access except the actor | Pet marked as passed away | **Marie** marked **Luna** as passed away | No | No |
| R18 | `shareInviteReminder` (new) | Invitee | Day 7 of an unanswered invite (N6) | Reminder: **Marie** invited you to care for **Luna** | Yes (it is the same pending object) | No |

**Notes on the catalogue**

- **R13 is future scope.** Ownership transfer is immediate today (`routes/pets/transferRouter.js`); there is no
  request-and-accept flow. R13 is only built if such a flow is added. Until then, R14 is the only ownership notice,
  and it is mandatory.
- **R17 (memorial)** has its own quiet treatment: no actor avatar, a memorial icon, never grouped, no push by default
  (inbox only), and it follows the existing passed-away ledger to avoid duplicates (`lib/petDataLifecycle.js`).
- **R18** does not create a second needs-response row. It bumps the existing R1/R8 row back to unread and sends a push
  if the user's settings allow it. It is sent once per invite (idempotent on invite id).

Org/foster workflow items (placements, custody, adoption, agreement withdrawal) remain `administrative`, keep their
current types, and appear in the Activity tab.

### 3.3 Suggestion catalogue (initial set)

| # | `type` | Source signal | Example headline | Primary action |
|---|---|---|---|---|
| S1 | `suggestionMissingRecurringCare` | Pet species/age profile lacks a commonly recurring item (e.g. yearly vaccine, deworming) | **Luna** has no deworming reminder. Cats usually need one every 3 months. | *Add reminder* |
| S2 | `suggestionWeightTrend` | Weight change ≥ threshold over window | **Luna**'s weight is up 8% since July | *Open weight chart* |
| S3 | `suggestionRepeatedSymptom` | Same symptom logged ≥ N times in window, not linked to a health issue | You logged vomiting 3 times this week for **Rex** | *Track as health issue* |
| S4 | `suggestionOverduePattern` | An item is repeatedly completed late (≥ 3 of last 4) | **Rex**'s flea treatment is often late. Move it to a different day? | *Adjust schedule* |
| S5 | `suggestionStaleRecord` | No weight logged in > X days for a species where it matters | No weight logged for **Luna** in 4 months | *Log weight* |
| S6 | `suggestionCareFamily` | Existing `care_family_suggestion_banner` logic | Group these 3 items as a "Dental care" routine? | *Review* |
| S7 | `suggestionShareCoverage` | Owner has an upcoming absence and no carer is assigned | You're away 12–19 Oct and no one is assigned to **Luna** | *Assign someone* |

Thresholds (`N`, `X`, percentages, windows) are configuration values owned by care intelligence, not by the client.
They MUST be overridable per environment so UAT/E2E can trigger each type with seeded data (§13.15).

### 3.5 Account catalogue (security & subscription)

**What exists today**, checked against the code:

- Password change and reset exist (`routes/auth/passwordRouter.js`), and both revoke all refresh sessions.
- Refresh sessions have rotation and **reuse detection**, which revokes the whole session family (`lib/refreshSessions.js`).
- Account erasure (`lib/account/accountErasureService.js`) and data export (`GET /me/export`) exist.
- There is **no email-change flow**: `PUT/PATCH /me` does not update the email.
- Refresh sessions store **no device information**, so "new device" detection needs a new `device_label` and first-seen data (N13).
- Logout (`POST /logout`) revokes **all** sessions today. A normal logout MUST NOT trigger A6.
- Subscriptions run **client-side via RevenueCat**, with no server webhook, and the billing provider is under review
  (`docs/domains/subscription`). Subscription events need a server-side entitlement source first.

#### 3.5.1 Security events

| # | `type` | Trigger | Example copy | Needs response | Channels |
|---|---|---|---|---|---|
| A1 | `accountNewSignIn` | Login creating a session family from a device label not seen on this account in the last 90 days | New sign-in to your account: **Chrome on Windows**, today 14:02 | **Yes**: "This was me" / "Secure my account" | Inbox + email + push to *other* devices. **Mandatory.** |
| A2 | `accountPasswordChanged` | Password changed or reset | Your password was changed | No (row offers "Secure my account" for 7 days) | Inbox + email. **Mandatory.** |
| A3 | `accountSessionsRevoked` | Refresh-token **reuse detected** (possible stolen token). Not a normal logout or password change (A2 covers that). | For your security, we signed you out on all devices | No | Inbox + email. **Mandatory.** |
| A4 | `accountEmailChangeRequested` *(when the email-change flow is built)* | Email change started | Sent to the **old** address: someone asked to change your email to f•••@g•••.com | Email only, with a "Cancel this change" link that cancels the change and doesn't sign anyone in | Email. **Mandatory.** |
| A5 | `accountEmailChanged` *(when built)* | Email change confirmed | Your sign-in email is now f•••@g•••.com | No | Inbox + email to **both** addresses. **Mandatory.** |
| A6 | `accountDeletionRequested` | Erasure started | Your account and data will be deleted. This can't be undone. | No | **Email only** (the account is going away). **Mandatory.** |

**"Secure my account"** (A1, A2) is a single in-app flow: revoke all sessions except the current one → force a
password change → show the list of recently seen device labels. It never asks for credentials in an email.

#### 3.5.2 Subscription events (provider-agnostic, N12)

| # | `type` | Trigger | Example copy | Needs response | Channels |
|---|---|---|---|---|---|
| A7 | `subscriptionActivated` | Entitlement becomes active (purchase, restore, family share) | **Unlimited** is active, enjoy unlimited pets and reports | No | Inbox |
| A8 | `subscriptionRenewalUpcoming` | 7 days before an **annual** renewal (monthly: none) | Your Unlimited plan renews on 12 Nov | No (links to manage subscription) | Inbox + email |
| A9 | `subscriptionPaymentIssue` | Billing retry / grace period started | We couldn't renew Unlimited. Update your payment method to keep your features. | **Yes**: "Update payment" deep-links to the store/provider management page | Inbox + email + push. **Urgent (D11).** |
| A10 | `subscriptionEnded` | Entitlement lapsed (cancelled, expired, refunded) | Unlimited has ended. Your data is safe; here's what changes on Free. | No (links to the paywall and to "what changes") | Inbox + email |
| A11 | `subscriptionTrialEnding` *(only if trials are offered)* | 3 days before a trial converts | Your free trial ends on 12 Nov | No | Inbox + push |

Subscription notices are sent only to the **subscribing account**, never to co-carers. A10 MUST state that no data is
deleted, and what Free limits apply.

#### 3.5.3 Requirements

| ID | Requirement |
|---|---|
| FR-ACC-1 | A1–A6 cannot be turned off (§8.3). They are excluded from grouping, mute, digests and rate limits. |
| FR-ACC-2 | A1 counts in the bell number until the user answers. "This was me" resolves it. "Secure my account" resolves it after the flow completes. An unanswered A1 auto-resolves after 14 days. |
| FR-ACC-3 | A1 is not sent for the very first sign-in after signup, or when the device label matches a label seen in the last 90 days. If the label cannot be determined, it is treated as "Unknown device" and A1 **is** sent. |
| FR-ACC-4 | Security emails contain no sign-in links, codes or buttons that authenticate. They tell the user to open the app, or to reset the password from the sign-in screen (N11). A4's "Cancel this change" link is single-use, cancels only the change, and does not sign anyone in. |
| FR-ACC-5 | Email addresses in notices are masked (`f•••@g•••.com`). Device labels are coarse (OS + browser/app family). No IP or location is stored or shown (N13). |
| FR-ACC-6 | Subscription events are created from a **server-side entitlement source** (provider webhook or server receipt validation), and are idempotent per provider event id. Without one, A7–A11 are not emitted, and the client MUST NOT synthesise them. |
| FR-ACC-7 | A9 is pinned as urgent until the entitlement recovers (auto-resolved → "Payment updated, you're all set") or ends (then A10). |
| FR-ACC-8 | A8 and A10 copy follow consumer-law expectations (clear renewal date, amount if the provider gives it, how to cancel). Copy is reviewed alongside `assets/legal/`. |
| FR-ACC-9 | Account rows are never shown to anyone except the account holder, and are deleted with the account (A6 is email only for this reason). |

### 3.4 Type → kind migration matrix

Wire `type` values keep their current camelCase spelling (N3). Only the server's type→kind map
(`server/lib/notificationKind.js`) changes. Every emitter MUST pass an explicit `type`; `general` is not allowed
for new rows after PR3.

| Current `type` (emitter) | Current kind | v2 kind | v2 `type` |
|---|---|---|---|
| `overdue`, `due_soon` (`checkDueNotifications.js`) | care | — (no inbox row; push only) | unchanged |
| `shareInviteReceived` | administrative | relationship | unchanged |
| `shareInviteAccepted`, `shareInviteDeclined` | care (not in admin set) | relationship | unchanged |
| `householdInviteReceived` (`householdInviteService.js`) | care (not in admin set) | relationship | unchanged |
| `absenceGuestGranted` | administrative | relationship | unchanged |
| `general` — ownership transferred (`pets/transferRouter.js`) | care | relationship | `ownershipTransferCompleted` |
| `general` — passed away (`petDataLifecycle.js`) | care | relationship | `petPassedAway` |
| `general` — placements, adoption journeys, foster placements, org pets (`organizations/**`, `fosterPlacements.js`) | care | administrative | specific type per emitter, listed in PR3 |
| `general` — share link accepted, "X is now following" (`services/sharing/shareLinkService.js`) | care | relationship | `shareInviteAccepted` (R2) |
| `general` — "Stopped following" to owner (`services/sharing/shareAccessService.js`) | care | relationship | `shareMemberLeft` (R7) |
| `general` — "Sharing ended" to removed user (`services/sharing/shareAccessService.js`) | care | relationship | `shareAccessRemoved` (R6, mandatory) |
| `general` — care-intelligence evaluation harness | care | — (test only) | removed |
| `fosterRequest*`, `fosterInvitation*`, `fosterApproval*`, `session*Soon`, `agreementWithdrawn`, `connectionRequestReceived`, `pending*Received`, `adminMessageReceived` | administrative | administrative | unchanged |

The table is complete for the `type: 'general'` emitters on `main` at commit `4f3325d`+3 (transfer ×2, passed-away ×1, foster placements ×4, adoption journeys ×3, placement actions ×5, share access ×2, share link ×1). Legacy rows are classified by **emitter title** where `type` is `general`; the migration ships a fixture per emitter. PR3 MUST include a test that fails if any
`createNotification` call omits `type` or uses `general`.

## 4. Care reminders after v2

| ID | Requirement |
|---|---|
| FR-CR-1 | The server MUST NOT create inbox rows with `kind=care` after the v2 cut-over. |
| FR-CR-2 | Care reminders MUST continue to be delivered as push/local notifications according to existing reminder settings and D21/D25 recipient rules. |
| FR-CR-3 | Tapping a care reminder push MUST deep-link to the care item / occurrence, exactly as today. |
| FR-CR-4 | Care Actions (dashboard) and Actions (`/pc/events`) remain the single source of truth for due/overdue items. |
| FR-CR-5 | Existing rows of type `overdue` / `due_soon` MUST be archived (not deleted) by migration and excluded from inbox lists and badge counts. Other `care`-kind rows are **reclassified** per §3.4, not archived. A blanket "archive all `care`" would hide ownership-transfer and memorial notices, which are stored as `general`/`care` today. |

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
| FR-IN-7 | The last selected tab is remembered **per device, for the app session only** (local, not synced). On a fresh launch the inbox opens on Activity, unless the user arrived from a suggestion push or digest (then For you). |
| FR-IN-8 | On wide layouts the inbox remains the right slide-over panel (D8). On compact layouts it is a full screen. There is **one route and one provider**, with two presentations: `notifications_screen.dart` and `notification_panel.dart` render the same tab widget, and nothing is duplicated between them. |

### 5.2 Row anatomy (Activity)

| ID | Requirement |
|---|---|
| FR-AR-1 | Each row MUST show the actor avatar (or a system icon if there is no actor) with the subject-pet avatar as a small overlay badge when a pet is involved. |
| FR-AR-2 | Each row MUST show a sentence where the actor and the object (pet/household) are bold, plus a relative timestamp. An absolute date/time appears on long-press or hover. |
| FR-AR-3 | Unread rows MUST have a visible unread marker that does not rely on colour alone (dot + bold weight). |
| FR-AR-4 | Tapping a row MUST mark it read and navigate to its target (pet sharing screen, household screen, transfer screen…). If the target no longer exists or the user has lost access, show a neutral "This item is no longer available" state instead of an error. |
| FR-AR-5 | On rows with inline actions, the row body stays a navigation target (it opens the full detail screen), and the inline buttons are separate controls that do not trigger row navigation. Focus order: row → primary → secondary. Screen readers expose the row as one element, with the actions as custom actions as well as focusable buttons. |
| FR-AR-6 | Inline action buttons are at least **48×48 dp** (`design.mdc`). The NFR-4 floor of 24×24 applies only to secondary affordances such as the overflow menu. |

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
| FR-BG-4 | The badge MUST update immediately after the user's own actions, and within 5 s of a push-triggered refresh (see FR-BG-6/7 for the transport). |
| FR-BG-5 | The badge count is capped visually at "9+". |

#### 5.4.1 Indicator matrix (normative)

An item counts only while it is **unread, not archived, and not resolved**.

| Item | Bell number | Bell dot | Activity tab indicator | For you tab indicator |
|---|---|---|---|---|
| Needs response (R1, R8, R18 bump, D10 pending) | ✔ counts | — | ✔ counts | — |
| Urgent (D11), whether or not it needs a response (includes A9) | ✔ counts | — | ✔ counts | — |
| A1 new sign-in, unanswered | ✔ counts | — | ✔ counts | — |
| Other relationship / administrative | — | ✔ if bell number = 0 | dot | — |
| Suggestion in state `new` | — | ✔ if bell number = 0 | — | dot |
| Resolved, archived, care reminder | — | — | — | — |

The Activity tab number is therefore always **equal to** the bell number. FR-IN-2 is read with this matrix: the
Activity count = needs response + urgent.

#### 5.4.2 Refresh transport

| ID | Requirement |
|---|---|
| FR-BG-6 | Badge and lists refresh: (a) immediately after the user's own action, from the server response; (b) when the app returns to the foreground; (c) when a push is received (data/silent payload triggers a refresh); (d) by polling the badge endpoint every **60 s while the app is in the foreground**, and every **15 s while the inbox is open**. No WebSocket/SSE in v2. |
| FR-BG-7 | FR-BG-4's "within 5 s" applies to cases (a)–(c). Cross-device sync without a push is bounded by the polling interval. |

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
| FR-GR-1 | Rows whose `type` is on the allowlist in §6.4.1, with the same subject (pet or household), within the rolling 24 h window MUST collapse into one row using that type's headline template, e.g. "**Paul** and **2 others** accepted your invites to **Luna**". |
| FR-GR-2 | Tapping a **grouped** row expands it in place, without navigating. Each member line has its own timestamp and is itself tappable to navigate to its target (FR-AR-4). FR-AR-4's tap-to-navigate applies to single rows and to member lines, never to the group header. |
| FR-GR-3 | Needs-response, mandatory and urgent items are NEVER grouped. |
| FR-GR-4 | A grouped row counts as **one** item for the dot/indicator. It is unread while any member is unread. Opening or expanding the group marks **all** members read in a single request. |

#### 6.4.1 Grouping model (N2)

- **Storage:** one row per recipient per event (FR-AC-1 is unchanged). There is no group table and no row mutation.
- **Read model:** `GET /notifications?tab=activity` returns items that are either single rows or groups. A group is
  `{groupId, type, subjectId, memberIds[], count, latestAt, unread, headline}`.
  `groupId = hash(type, subjectId, window start)`. The window is a **rolling 24 h anchored on the first member**, so
  a group's id stays stable across refreshes.
- **Read API:** `POST /notifications/read` accepts `ids[]` or `groupId`. A `groupId` marks every member read.
- **Push:** push grouping (FR-PU-1) uses the same `type` + subject key with a 2-minute debounce. Push and inbox
  share the key function but not the window.
- **Allowlist and headline templates.** Only these types group:

| `type` | Group headline (EN) |
|---|---|
| `shareInviteAccepted` | **Paul** and **2 others** accepted your invites to **Luna** |
| `shareMemberLeft` | **Paul** and **2 others** stopped caring for **Luna** |
| `householdMemberJoined` | **Paul** and **2 others** joined the **Dupont household** |
| `householdPetAdded` | **Luna** and **2 other pets** were added to the **Dupont household** |

All other types are never grouped, including every needs-response, mandatory, urgent and memorial type.

## 7. For you — Agatha Suggestions

### 7.1 Generation (server-side)

| ID | Requirement |
|---|---|
| FR-SG-1 | Suggestions MUST be generated server-side by a scheduled job (at least daily) and on relevant data changes (e.g. new weight entry). They are persisted as `kind=suggestion` rows. |
| FR-SG-2 | Each suggestion has: `type`, `pet_id`, `headline`, `rationale` (one sentence), `evidence` (structured: data points and window), `primary_action` (deep link + label), `confidence` (0–1), `expires_at`, `dedupe_key`. |
| FR-SG-3 | Only suggestions with confidence ≥ the configured threshold (default 0.7) are created. |
| FR-SG-4 | Recipients: S1–S6 → pet owner and Full-access members. S7 → **record owner only** (N7). Can-log-care and view-only members never receive suggestions. Org/foster pets follow scope rules. |
| FR-SG-5 | A `dedupe_key` (e.g. `weight_trend:<pet>:<window>`) MUST prevent the same suggestion from being active twice. A refreshed signal updates the existing row rather than creating a new one. |
| FR-SG-6 | From PR5, `care_recommendations_provider` and the pet-profile suggestion cards (`care_suggestion_card`, `care_family_suggestion_banner`) read the **same API** as For you, filtered by pet. Dismissing a card in one place dismisses it everywhere. No suggestion is computed only on the client. Until PR5, profile cards stay as they are and For you shows its empty state; the two never run side by side. |
| FR-SG-7 | S6's `dedupe_key` reuses the existing care-family banner's grouping key, so that users who dismissed the banner before PR5 do not see the same suggestion again. |

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

`new → seen → (acted | dismissed | not_relevant | expired | completed)`. When the user **opens the For you tab**
(or a pet profile showing the card), every suggestion rendered in that view becomes `seen`. This does not depend on
dwell time, so screen-reader and keyboard users get the same result. Only `new` counts as unread.

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
| Invites & requests (R1, R8, R18; R13 when built) | always | on | on | — |
| Access & membership changes (R2–R7, R9–R12, R14–R16) | always | on | off | — |
| Organisation & foster (administrative) | always | on | per existing prefs | — |
| Agatha Suggestions | on | **weekly digest** (off / weekly digest / instant) | off¹ | inbox + weekly digest |
| Account security (A1–A6) | always | on (A1 always) | always | locked, mandatory |
| Subscription (A7–A11) | always | A9/A11 on | A8–A10 on | — |
| Care reminders | — (not in inbox) | existing reminder settings | existing | unchanged |

¹ Email digest defaults to **on** for users with no push-capable device (N8, FR-DG-5).

### 8.2 Requirements

| ID | Requirement |
|---|---|
| FR-SE-1 | Settings MUST persist server-side in `notification_preferences` and apply on all devices. |
| FR-SE-2 | Turning **Agatha Suggestions → In-app** off stops generation for that user (not only display) and hides existing active suggestions. The For you tab then shows an "Agatha Suggestions are off" state with a toggle. |
| FR-SE-3 | Per-suggestion-type toggles are available under Agatha Suggestions (S1–S7), including those auto-suppressed by FR-FB-3. |
| FR-SE-5 | The existing per-pet mute (`mutedPetIds`) applies to suggestions and to non-mandatory relationship **push** for that pet. Inbox rows are still created for relationship items, and mandatory items ignore mute. |
| FR-SE-6 | Help/FAQ and privacy copy MUST state that turning Agatha Suggestions off stops them being **computed**, not only hidden. |
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
| FR-PU-1 | Relationship pushes are sent at most once per event, and, for allowlisted types only (§6.4.1), grouped if several arrive within 2 minutes ("Paul and 2 others joined…"). |
| FR-PU-2 | v2 has **no in-app quiet-hours setting** (none exists today). We rely on OS Focus / Do Not Disturb. Relationship and suggestion pushes are sent with a non-time-sensitive interruption level; urgent (D11) pushes are sent as time-sensitive. An in-app quiet-hours setting is deferred to `changes/deferred.md`. |
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
| FR-DG-5 | Users with no push-capable device registered (for example, web only) get the digest **by email**, on by default (N8). If they later register a push device, the email digest stays on until they turn it off. |

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
| NFR-8 Data retention | Inbox rows are archived at 90 days and hard-deleted at 365 days, for every kind (N9). Suggestion feedback is kept 365 days. Org/foster evidence (approvals, withdrawals, custody) MUST already be in `audit_events` / pet reports when the row is created. Inbox deletion never removes compliance evidence (N5). |
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
| FR-MG-2 | Existing `overdue`/`due_soon` rows are set to `archived` (kept for reports per `pet_report_notifications_section`). Other legacy rows are reclassified per §3.4. Rows that cannot be classified stay visible as `administrative` with their original text. |
| FR-MG-3 | Existing share/household/transfer rows currently stored as `administrative` are re-classified to `relationship` where they match a §3.2 type. Unmatched rows stay `administrative`. |
| FR-MG-4 | Older clients receiving unknown `kind` values MUST NOT crash. The current client parser defaults unknown values to `care`, so the server MUST omit `relationship`/`suggestion` rows for clients below the minimum version, or the client parser MUST be updated first (ship the parser in PR 1). |
| FR-MG-5 | Decision docs are updated per §0: D7/D8 superseded, D9/D10 amended, N1–N9 added. See the AC-MG-5 checklist. |
| FR-MG-6 | **Reversibility is limited to the schema.** `migrate down` removes the new columns/tables and restores the old type→kind map. Data reclassification and archival are **not** reversed automatically. Instead, a pre-migration backup is taken, and `docs/ops` documents the restore. |

## 12. Rollout (atomic PRs)

| PR | Outcome | Verifiable by |
|---|---|---|
| 1 | Stop creating `overdue`/`due_soon` inbox rows. Migration: archive existing `overdue`/`due_soon` rows **only**, and backfill-reclassify every other legacy row per §3.4 (no blanket archive). Client parses new kinds safely. Doc checklist AC-MG-5 lands before this PR. | AC-CR-*, AC-MG-* |
| 2 | Two-tab inbox (Activity / For you), empty states, explainer, badge rules | AC-IN-*, AC-BG-* |
| 3 | Relationship emitters per §3.2 (R1–R12, R14–R17; R13 excluded as future), the §3.4 type→kind map for new rows, explicit `type` everywhere, and privacy rules | AC-AC-*, AC-PR-* |
| 4 | Inline actions + Needs your response *(core)*; grouping, R4/R18 *(enhancement)* | AC-IA-*, AC-GR-* |
| 5 | Server-generated suggestions S1–S7, rate limits, cards, feedback | AC-SG-*, AC-FB-* |
| 6 | Settings matrix, mandatory items *(core)*; email + weekly digest *(enhancement)* | AC-SE-*, AC-DG-* |
| 7 | Account security A1–A3, A6: device label on sessions, "Secure my account" flow, security emails *(core)* | AC-ACS-* |
| 8 | Subscription A7–A11 *(core, **blocked** until the billing provider is chosen and a server entitlement source exists)* | AC-SUB-* |
| — | A4/A5 ship with the email-change feature (not yet built), using the rules in §3.5 | AC-ACS-8/9 |

**BDD strategy.** PR1 creates `notifications_v2.feature`. In the same PR, scenarios in `notifications.feature` that
assert care rows in the inbox or badge = unread count are tagged `@legacy` and excluded from the coverage gate.
Each later PR adds its v2 scenarios. PR6 deletes the `@legacy` scenarios. `check_bdd_coverage.js` must not regress
at any PR. If the net count drops in PR1, PR1 adds enough v2 scenarios (AC-CR, AC-MG) to compensate.

**PR3 also includes:** the §3.4 type map, explicit `type` at every emitter, and the "no `general`" guard test.

**PR7 is security-sensitive.** Read `.cursor/agent-kernel/protocols/security.md` and `data-lifecycle.md` first. A DPIA note is required for storing the device label (N13).

**Size watch.** `notification_panel.dart` is split when tabs land in PR2 (tab shell, Activity list, For you list,
row widgets), before inline actions are added in PR4.

## 13. Acceptance criteria

Written in Given/When/Then form so they can be turned into BDD scenarios with minimal rewording.

### 13.1 Care reminders removed from inbox (AC-CR)

- **AC-CR-1** — Given a pet with a vaccine due today, when the reminder job runs, then a push/local reminder is delivered **and** no inbox row is created **and** the bell badge does not change.
- **AC-CR-2** — Given the same pet, when I open Care Actions and Actions, then the due item is listed there exactly as before v2.
- **AC-CR-3** — Given I tap the care reminder push, then I land on that occurrence's detail screen.
- **AC-CR-4** — Given I had 12 unread `overdue`/`due_soon` rows before migration, when the migration runs, then those rows are archived, they do not appear in either tab, and the badge does not count them.
- **AC-CR-6** — Given I received an ownership-transfer notice and a passed-away notice before migration (stored as `general`), when the migration runs, then both appear in Activity as `relationship` rows. Neither is archived.
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
- **AC-IN-9** — Given it is my first inbox open after v2, then the explainer is shown once. Once I dismiss it, it never appears again on any device. The dismissal is stored server-side as a `notification_preferences` key (`v2ExplainerDismissedAt`).
- **AC-IN-11** — Given I switch to For you and close the inbox, when I reopen it in the same app session, then For you is selected. After an app restart, Activity is selected.
- **AC-IN-10** — Given both tabs are empty, then each shows its specific empty-state copy (FR-EM-1/2).

### 13.3 Badge (AC-BG)

- **AC-BG-1** — Given 2 unread pending invites and 1 unread "member joined", then the badge shows **2**.
- **AC-BG-2** — Given 0 pending items, 1 unread "member joined" and 1 new suggestion, then the badge shows a **dot** without a number.
- **AC-BG-3** — Given everything is read, then no badge is shown.
- **AC-BG-4** — Given I accept an invite inline, then the badge decrements immediately without a reload.
- **AC-BG-5** — Given the invite is accepted on another device and this device receives the push, then within 5 s the badge on this device decrements. Without a push, it decrements at the next poll (≤ 60 s in the foreground, ≤ 15 s with the inbox open). E2E tests wait on the API state, never on a fixed sleep.
- **AC-BG-8** — Given an urgent agreement-withdrawal item and 1 pending invite, all unread, then the bell shows **2** and the Activity tab shows **2** (indicator matrix §5.4.1).
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
- **AC-AC-9** — Given Marie transfers Luna to Paul (the immediate flow that exists today), then both receive R14. R14 cannot be muted, and it always sends an email. (R13 criteria apply only if a request flow is built.)
- **AC-AC-14** — Given Marie marks Luna as passed away, then everyone else with access gets one R17 row with the memorial treatment and no push. Re-marking does not create duplicates.
- **AC-AC-15** — Given Paul has not answered Marie's invite after 7 days, then Paul's R1 row becomes unread again with a reminder line, and no second row is created. On day 14, the invite expires (R4 to Marie).
- **AC-AC-16** — Given any `createNotification` call without an explicit `type`, or with `general`, then the server test suite fails.
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
- **AC-IA-4** — *(Applies only if R13 is built.)* When I tap Accept on R13 (ownership), then a confirmation sheet is always shown before anything happens.
- **AC-IA-9** — Given an R1 row, when I tap the row body (not the buttons), then I land on the full invite screen. When I tap Accept, I do not navigate away.
- **AC-IA-10** — Given inline Accept/Decline buttons, then each has a hit area of at least 48×48 dp.
- **AC-IA-5** — Given the network fails during Accept, then the buttons re-enable, an inline error with **Retry** is shown, and no state changes.
- **AC-IA-6** — Given the inviter cancelled the invite after my inbox loaded, when I tap Accept, then the row refreshes to "Invite cancelled by Marie" with an "Already handled" note and no error dialog.
- **AC-IA-7** — Given a pending foster placement (D10 administrative), then it appears in **Needs your response** with inline actions, following the same rules.
- **AC-IA-8** — Given a keyboard-only user, then Tab moves through row → Accept → Decline in order, and Enter/Space activates them.

### 13.7 Grouping (AC-GR)

- **AC-GR-1** — Given Paul, Léa and Sam each accept invites to Luna within 24 h of the first acceptance, then Marie sees one row "Paul and 2 others accepted your invites to Luna".
- **AC-GR-6** — Given a grouped row, when the list is refreshed, then the group keeps the same `groupId`, and a 4th acceptance inside the window joins it ("Paul and 3 others…").
- **AC-GR-7** — Given two R6 removals (not on the allowlist), then they are never grouped.
- **AC-GR-2** — When Marie expands it, then 3 entries with individual timestamps are shown, and the group becomes read.
- **AC-GR-3** — Given 2 pending invites for the same pet, then they are shown as 2 separate rows (actionable items are never grouped).
- **AC-GR-4** — Given events 25 h apart, then they are not grouped.
- **AC-GR-5** — Given grouping occurs, then the screen-reader label announces the full sentence with the count ("Paul and 2 others…").

### 13.8 Read / resolved / archive (AC-ST)

- **AC-ST-1** — When I tap a single (non-grouped) row, then it is marked read and I navigate to its target. When I tap a group header, then it expands without navigating (AC-GR-2).
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
- **AC-SG-14** — Given any suggestion copy, then it contains no diagnosis or dosage wording (copy review checklist, EN and FR). French health terms (S2, S3) are reviewed for a plain, non-clinical register (e.g. "a vomi" rather than "épisodes émétiques").

### 13.10 Suggestion feedback (AC-FB)

- **AC-FB-1** — When I **Dismiss** an S5 for Luna, then it disappears, and the same suggestion does not reappear for 30 days even if the condition persists.
- **AC-FB-2** — When I mark S4 **Not relevant** for Rex, then no S4 is created for Rex for 90 days, but S4 for Luna can still appear.
- **AC-FB-3** — Given I mark S4 Not relevant for 3 different pets within 90 days, then S4 is suppressed account-wide, and settings show S4 turned off.
- **AC-FB-4** — When I choose an optional reason, then it is recorded. Skipping the reason still records Not relevant.
- **AC-FB-5** — When I open the For you tab, then every rendered suggestion becomes seen, and the For you dot clears, regardless of dwell time or assistive technology.
- **AC-FB-6** — Given I dismiss an S1 card on Luna's profile, then it is gone from For you too (single source, FR-SG-6).

### 13.11 Settings (AC-SE)

- **AC-SE-1** — When I open notification settings, then I see the category × channel matrix with the defaults in §8.1.
- **AC-SE-2** — Given I turn Agatha Suggestions → In-app off, then active suggestions disappear, no new ones are generated, and For you shows the "Suggestions are off" state with a toggle.
- **AC-SE-3** — Given I turn off Access & membership push, then R7 creates an inbox row but no push.
- **AC-SE-4** — Given I turned off all relationship email, when Marie removes me from Luna (R6, mandatory), then I still receive the email and the inbox row.
- **AC-SE-5** — Given mandatory items, then their toggles appear locked with "Sent for your account's security".
- **AC-SE-6** — Given OS push permission is denied, then push toggles show the device-settings hint instead of an enabled state.
- **AC-SE-7** — Given I change a setting on web, then my phone reflects it on the next settings load.
- **AC-SE-9** — Given Luna is muted, then no suggestions are generated for Luna and relationship pushes about Luna are not sent, but relationship inbox rows still appear. A mandatory R6 about Luna still sends its email.
- **AC-SE-8** — Given Care reminders, then the matrix shows no in-app inbox option, and a link points to the existing reminder settings.

### 13.12 Push, email & digest (AC-DG)

- **AC-DG-1** — Given the default digest setting and 2 new suggestions this week, when Monday 09:00 local comes, then I receive one push "Agatha has 2 suggestions for Luna and Rex". Opening it lands on For you.
- **AC-DG-2** — Given no new suggestions since the last digest, then no digest is sent.
- **AC-DG-3** — Given Instant mode, then each new suggestion sends one push, and the weekly caps still apply.
- **AC-DG-4** — Given 3 people join my household within 2 minutes, then I receive a single push "Paul and 2 others joined the Dupont household".
- **AC-DG-5** — Given an R9 push, then it is sent with a non-time-sensitive interruption level. Given a D11 urgent push, then it is sent as time-sensitive. (There is no in-app quiet-hours setting in v2.)
- **AC-DG-8** — Given a web-only user with 1 new suggestion, when the digest time comes, then they receive the digest by email.
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

- **AC-MG-1** — After migration, `overdue`/`due_soon` rows are archived and counted 0 in the badge. Every other legacy row is reclassified per §3.4. The total row count is unchanged (nothing deleted).
- **AC-MG-7** — Given legacy rows from each `general` emitter in §3.4 (one fixture each), then after migration each has the v2 kind/type listed in the matrix.
- **AC-MG-2** — Pre-existing share/household/transfer rows show in Activity with the `relationship` treatment.
- **AC-MG-3** — A client at the previous release receives no unknown kinds (or parses them safely) and does not crash.
- **AC-MG-4** — `migrate down` removes the v2 schema additions and restores the old type→kind map. A backup is taken before `up`, and the restore runbook exists in `docs/ops`.
- **AC-MG-5** — The documentation checklist is complete before this spec is marked `accepted`:
  - [ ] `notification-decisions.md`: a "Notifications v2 supersession" subsection mirroring §0 (D7, D8, D9, D10, N1–N9).
  - [ ] `features/specs.md`: axes table updated (kinds, `pet_care` scope wording, tabs instead of chips).
  - [ ] `features/journeys.md`: care-in-inbox, chips and combined badge journeys rewritten.
  - [ ] `cross-domain/changes/program-contract.md` §3: a footnote pointing to this spec over the old diagram.
  - [ ] Help/FAQ l10n strings (EN/FR) on reminders, snooze and "in-app notifications for due items" updated.
  - [ ] `changes/deferred.md`: quiet hours, R13 request flow, a "dot only for needs-response" badge option, S7 recipients revisit, approximate sign-in location (pending DPIA), and A4/A5 (pending the email-change feature).
  - [ ] `docs/domains/subscription`: link to A7–A11 and the server-entitlement prerequisite.
  - [ ] People domain docs: cross-link noting that ownership transfer is immediate in the API (no accept step), so R13 stays future. The contradiction is tracked on the People backlog.
  - [ ] `changes/plans.md`: the link points to the accepted revision.
- **AC-MG-6** — Given `householdInviteReceived` and `shareInviteAccepted` rows (today wrongly defaulted to `care`), then after migration both are `relationship` and visible in Activity.

### 13.15a Account security (AC-ACS)

- **AC-ACS-1** — Given I have only signed in from "Safari on iOS", when I sign in from "Chrome on Windows", then I get an A1 row, an email, and a push on my iPhone. The row shows the device label and time, with no IP or location.
- **AC-ACS-2** — Given A1, when I tap **This was me**, then it resolves and the bell number decrements.
- **AC-ACS-3** — Given A1, when I tap **Secure my account**, then all other sessions are revoked, I must set a new password, and A1 resolves when the flow completes.
- **AC-ACS-4** — Given I sign in again from "Chrome on Windows" within 90 days, then no A1 is sent. My very first sign-in after signup also sends no A1.
- **AC-ACS-5** — Given I change my password, then I get A2 in the inbox and by email, and I cannot turn either off in settings.
- **AC-ACS-6** — Given a revoked refresh token is replayed (reuse detection), then the session family is revoked and I get A3 by email and in the inbox. Given I simply log out, then no A3 is sent.
- **AC-ACS-7** — Given any security email, then it contains no sign-in link, code or authenticating button. The email address is masked.
- **AC-ACS-8** — *(When email change exists.)* Given I request an email change, then the old address gets A4 with a single-use "Cancel this change" link. Using that link cancels the change and does not sign anyone in.
- **AC-ACS-9** — *(When email change exists.)* Given the change is confirmed, then both addresses get A5.
- **AC-ACS-10** — Given I request account deletion, then I receive A6 by email only, and no inbox row is created.
- **AC-ACS-11** — Given another member of Luna's care team, then they never see my account rows (API returns 404 by id).
- **AC-ACS-12** — Given Luna is muted or suggestions are off, then account notices are unaffected.

### 13.15b Subscription (AC-SUB) — run once a server entitlement source exists

- **AC-SUB-1** — Given my purchase is confirmed by the server entitlement source, then I get A7 once. Replaying the same provider event creates no duplicate.
- **AC-SUB-2** — Given an annual plan renewing on 12 Nov, then on 5 Nov I get A8 (inbox + email) with the date and how to cancel. A monthly plan gets no A8.
- **AC-SUB-3** — Given a billing retry starts, then A9 is pinned as urgent, counts in the bell, and sends a push. **Update payment** opens the store/provider page.
- **AC-SUB-4** — Given payment then succeeds, then A9 resolves to "Payment updated, you're all set" and the bell decrements. If the grace period ends instead, A9 resolves and A10 is created.
- **AC-SUB-5** — Given my subscription ends, then A10 states that no data is deleted and lists the Free limits.
- **AC-SUB-6** — Given co-carers on my pets, then they receive no subscription notices.
- **AC-SUB-7** — Given no server entitlement source is configured, then no A7–A11 rows are ever created, and the client does not create them from RevenueCat state.
- **AC-SUB-8** — Given trials are not offered, then A11 never fires.

### 13.15 Test hooks (AC-TH)

- **AC-TH-1** — In UAT/test, the care-intelligence thresholds and the generation job can be overridden and triggered on demand (admin/test-only endpoint, disabled in production), so each S-type can be produced from seeded data.
- **AC-TH-2** — The invite clock (day 7 and day 14) can be advanced in tests without real waiting.
- **AC-TH-3** — Test-only endpoints can simulate provider subscription events (activate, renewal due, billing retry, recovery, expiry), and can set a session's device label.

## 14. Open questions — resolved

| # | Question | Resolution |
|---|---|---|
| 1 | Invite expiry | 14 days, with one invitee reminder on day 7 that bumps the existing row (N6, R18). |
| 2 | S7 recipients | Record owner only (N7). Revisit if co-parents without owner rights report gaps. |
| 3 | Email digest without push | Yes, on by default for users with no push device (N8, FR-DG-5). |
| 4 | 90-day archive vs audit | Accepted. The inbox is not an audit log; evidence lives in `audit_events` and reports (N5, N9). |

Still open (non-blocking): whether to add a "dot only for needs-response" badge option later, depending on the
"inbox opens without action" metric.

## 15. Rev 2 change log (review incorporated)

| Review point | Change |
|---|---|
| Grouping vs idempotency | §6.4.1: read-model grouping, stable `groupId`, allowlist + headline templates, group read API (N2). |
| D9 / D10 supersession | §0 decision table; D9 extended, D10 amended. |
| Type codes | camelCase kept (N3); §3.4 full migration matrix. Code check found `general` used for transfers, memorial and org flows, and `householdInviteReceived` / `shareInviteAccepted` defaulting to `care`. These are now reclassified, not archived (FR-CR-5, AC-CR-6, AC-MG-6). |
| Reversibility | Schema-only `down` + backup runbook (FR-MG-6, AC-MG-4). |
| Badge vs tab | Normative indicator matrix §5.4.1; AC-BG-8. |
| Explainer / tab memory | Server-side explainer flag; tab memory per device and session (FR-IN-7, AC-IN-9/11). |
| Realtime | Defined transport, no sockets in v2 (FR-BG-6/7); AC-BG-5 bounded and sleep-free. |
| "Seen after 1 s" | Seen when the For you tab is opened (§7.4, AC-FB-5). |
| Per-pet mute, help copy | FR-SE-5/6, AC-SE-9. |
| Catalogue gaps | R17 memorial, R18 invite reminder; R13 marked future because transfer is immediate today. |
| Row tap vs inline actions | FR-AR-5/6 (48 dp), AC-IA-9/10. |
| Profile vs inbox suggestions | FR-SG-6/7 single source from PR5, no side-by-side run; AC-FB-6. |
| Retention vs audit | N5/N9, NFR-8. |
| Quiet hours | Not present in the product → OS Focus + interruption levels; in-app setting deferred (FR-PU-2, AC-DG-5). |
| BDD mid-rollout | `notifications_v2.feature` + `@legacy` plan in §12. |
| Test hooks | §13.15. |
| Doc drift | AC-MG-5 checklist. |
| Decision ID collision | New decisions use N1–N9 (D12–D16 are taken by roles). |

### Rev 2.1

| Review point | Change |
|---|---|
| FR-SG-4 contradicted N7 | S7 → record owner only; S1–S6 → owner + Full access. |
| Missing `general` emitters (sharing services on `main`) | Three rows added to §3.4; emitter counts pinned; AC-MG-7 fixture per emitter. |
| §12 PR1 said "archive existing" | Selective archive + backfill reclassification moved into PR1; PR3 covers new-row emitters. |
| AC-MG-1 stale | Aligned with FR-MG-2; AC-MG-7 added. |
| Grouped row: expand vs navigate | FR-GR-2 / AC-ST-1: the group header expands, member lines navigate. |
| FR-GR-1 / FR-PU-1 wording | Point to the §6.4.1 allowlist and templates. |
| §8.1 R13 / N8 | R13 marked "when built"; footnote for N8. |
| PR3 scope label | R1–R12, R14–R17 (R13 future). |
| Requirements drift check | New §0.1 traceability table with core/preserved/enhancement tiers and the scope rule. |
| Status workflow | Accepted only after the AC-MG-5 docs PR. |

### Rev 2.2

| Change | Detail |
|---|---|
| Account notifications added to scope (user decision) | New `account` kind (N10); security A1–A6 and subscription A7–A11 (§3.5); N11–N13; settings, badge matrix, rollout PR7/PR8, AC-ACS / AC-SUB, AC-TH-3. |
| Code-grounded constraints | Email change is not built (A4/A5 are conditional); no device data on sessions (new `device_label`, N13); logout revokes all sessions (it must not trigger A3); subscriptions are client-side RevenueCat (PR8 is blocked on a server entitlement source). |
