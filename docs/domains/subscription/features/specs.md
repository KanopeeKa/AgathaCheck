---
title: Subscription specs
owner: Documentation Team
audience: both
status: active
last_updated: 2026-10-08
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
- Playwright E2E: **deferred** (Sprint 7.2)

---

Regulatory copy references RevenueCat in privacy/terms assets (`flutter_app/assets/legal/`).
