---
title: BDD uncovered scenario triage
owner: Documentation Team
audience: agent
status: active
last_updated: 2026-10-04
tags: [quality, bdd, e2e]
---
# BDD uncovered scenario triage

Active Gherkin scenarios with no matching `@bdd` title in a non-frozen Playwright spec.
Regenerate the uncovered list with `node e2e/scripts/check_bdd_coverage.js --report-only`.

| Feature | Scenario | Decision | Notes |
|---------|----------|----------|-------|
| away_planning.feature | Guardian assigns a contact carer on the away plan page | **implement** | CARE E+F landed; extend away-plan Playwright coverage |
| guardian_dashboard.feature | Dashboard shows exactly three sections | **implement** | Pet Care dashboard IA; add to `guardian.dashboard.spec.ts` |
| health_tracking.feature | Adding a photo attachment to a health entry | **implement** | Care Item / health entry flows |
| health_tracking.feature | Viewing all health entries in the dashboard | **implement** | |
| health_tracking.feature | Grouping entries by due date | **implement** | |
| health_tracking.feature | Grouping entries by pet | **implement** | |
| health_tracking.feature | Grouping entries by species | **implement** | |
| health_tracking.feature | Multi-dose stack opens the care item view | **implement** | |
| health_tracking.feature | Viewing history for a health entry | **implement** | |
| health_tracking.feature | Creating a health issue for a pet | **implement** | |
| health_tracking.feature | Linking a health entry to a health issue | **implement** | |
| health_tracking.feature | Exporting health entries as PDF | **implement** | |
| health_tracking.feature | Filtering health entries by organisation | **defer** | Organisation-scoped health UI is frozen domain; revisit if org health returns |
| notifications.feature | Muting notifications for a specific pet | **implement** | |
| notifications.feature | Unmuting notifications for a pet | **implement** | |
| notifications.feature | Bell badge shows combined count across care and administrative notifications | **implement** | |
| notifications.feature | Notification kind filter narrows list without navigating | **implement** | |
| notifications.feature | Administrative notification with open object shows Action needed affordance | **implement** | |
| notifications.feature | Resolved administrative notification does not show Action needed | **implement** | |
| notifications.feature | Record owner notified when absence guest access is granted by another member | **implement** | Away-plan / absence integration |
| people.feature | People directory card opens person detail | **implement** | PEOPLE client programme |
| sharing.feature | Pet parent sees household members in who has access | **implement** | |
| sharing.feature | Carer stops following a shared pet | **implement** | |
| sharing.feature | Carer hides a shared pet from their list | **implement** | |
| sharing.feature | Hiding a shared pet via swipe | **implement** | |
| sharing.feature | Declining an email share invite | **implement** | |
| subscriptions.feature | Viewing the paywall on a free plan | **not-web** | Store / IAP flows; out of localhost Playwright scope |
| subscriptions.feature | Viewing premium features list | **not-web** | |
| subscriptions.feature | Purchasing a monthly subscription | **not-web** | |
| subscriptions.feature | Purchasing a yearly subscription | **not-web** | |
| subscriptions.feature | Purchase failure shows error | **not-web** | |
| subscriptions.feature | Viewing active subscription details | **not-web** | |
| subscriptions.feature | Managing active subscription | **not-web** | |
| subscriptions.feature | Restoring previous purchases | **not-web** | |
| subscriptions.feature | Restore purchases with no previous purchases | **not-web** | |
| subscriptions.feature | No subscription offerings available | **not-web** | |
| subscriptions.feature | Failed to load subscription offerings | **not-web** | |

**Gate:** 68% mapped active scenarios remains enforced by `check_bdd_coverage.js`; this table records product decisions only.
