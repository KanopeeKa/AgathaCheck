---
title: Subscription specs
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
tags: [domain,subscription,specs]
domain: subscription
---

# Subscription specs

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

## Tests

- BDD: `subscriptions.feature` (11 scenarios) — documents intended journeys
- Playwright E2E: **deferred** (Sprint 7.2)

---

Regulatory copy references RevenueCat in privacy/terms assets (`flutter_app/assets/legal/`).
