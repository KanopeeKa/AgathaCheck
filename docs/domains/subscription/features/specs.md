---
title: Subscription specs
owner: Documentation Team
audience: both
status: active
last_updated: 2026-11-11
tags: [domain,subscription,specs]
domain: subscription
feature_id: subscription
---

# Subscription

Premium tier purchase and entitlement flows (RevenueCat today). Billing provider under product review — see [deferred.md](../changes/deferred.md).

## Requirements

| ID | Requirement | Status |
|----|-------------|--------|
| **SUB-1** | Free and Unlimited tiers reflected in client `SubscriptionTier` + active flag. | delivered |
| **SUB-2** | Paywall reachable from Account → Subscription. | delivered |
| **SUB-3** | BDD `subscriptions.feature` documents intended purchase journeys. | delivered |
| **SUB-4** | Purchase outcomes: success (entitlement active), cancelled (no message), failed (localized), pending (purchase completed but entitlement not yet active). | delivered |
| **SUB-5** | Restore outcomes: restored (entitlement found), nothing to restore, failed; failed restore must not downgrade stored tier. | delivered |

## User journeys

Premium purchase and entitlement flows. **Billing provider under product review** — EU-based solution may replace RevenueCat. BDD spec `subscriptions.feature` (11 scenarios); Playwright E2E deferred until billing architecture is decided.

## Tiers

| Tier | Wire / client | Notes |
|------|---------------|-------|
| Free | `SubscriptionTier.free` | Default — core features |
| Unlimited | `SubscriptionTier.unlimited` + `isActive` | Premium entitlement via RevenueCat today |

Entity: `flutter_app/lib/features/subscription/domain/entities/subscription_status.dart`

## RevenueCat integration

- Service: `data/services/revenuecat_service.dart`
- Paywall UI: `presentation/screens/paywall_screen.dart`
- Entry: Account / My Details → Subscription (FAQ copy in `help_faq.feature`)

## Product status

Billing provider under **product review** — EU-based solution may replace RevenueCat. Do not invest in RevenueCat sandbox E2E until architecture is decided (see [changes/deferred.md](../changes/deferred.md)).

## Notifications

Subscription notices (activated, renewal upcoming, payment issue, ended, trial ending) are specified in [Notifications §3.5.2](/docs/domains/notifications/features/notifications-v2-spec.md) (A7–A11). They require a **server-side entitlement source** (provider webhook or server receipt validation) and are blocked until the billing provider is chosen. The client must not synthesise them from RevenueCat state.

## Tests

- BDD: `subscriptions.feature` (11 scenarios) — documents intended journeys
- Playwright E2E: **deferred** (Sprint 7.2) — store checkout cannot be mocked end to end

### Manual UAT — subscription disclosure (truthful outcomes)

Run on a build with live store products (TestFlight / Play internal / sandbox account as available):

| Check | Pass when |
| --- | --- |
| Offer cards | Each package shows **recurring price and cadence** from the store product period, an **auto-renew** sentence, **how to cancel**, and links to `/legal/terms-of-use` and `/legal/privacy-notice`. |
| Trial / intro | Trial or intro copy appears **only** when the store product carries an introductory price; the app never invents a trial length. |
| Best value | **Best Value** appears only when the annual package’s monthly cost is lower than the monthly package in the same offering; with one cadence there is no tag. |
| Manage subscription | **Manage subscription** opens the store `managementUrl` externally; if launch fails, localized copy with a **copyable URL** is shown; with no URL the control is absent or disabled with explanation. |
| Status date | The date is labelled **renewal** only when status says the subscription will renew; otherwise it reads as **active until**. |
| Purchase errors | Purchase and restore failures show localized messages — never raw exception text. |

Automated journey coverage for bell panel and consent lives in `trust_surfaces.feature` / `trust.surfaces.spec.ts`.

---

Regulatory copy references RevenueCat in privacy/terms assets (`flutter_app/assets/legal/`).
