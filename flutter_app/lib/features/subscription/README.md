---
title: Subscription feature
owner: Platform team
status: active
component_id: flutter.feature.subscription
last_updated: 2026-10-05
last_reviewed: 2026-10-05
---

# Purpose

Subscription status and paywall presentation (RevenueCat). **Non-goals:** payment webhooks (server).

## Public entrypoint

`package:pet_profile_app/features/subscription/subscription.dart`

## Public surface

| Symbol | Kind | Reason |
|--------|------|--------|
| `SubscriptionStatus` | domain entity | Entitlement display |
| `subscriptionProviders` | providers | Status and offerings |
| `PaywallScreen` | UI screen | Router destination |
| `initializeSubscriptionSdk` | bootstrap | `main.dart` startup (RevenueCat stays in `data/`) |

## Dependencies

| Allowed | Forbidden |
|---------|-----------|
| `auth`, `core/` | Exporting `data/` (RevenueCat service stays internal) |

## Side effects & freshness

RevenueCat SDK state; refresh on resume.

## Permissions

Store purchases; no extra server scopes.

## Tests

`flutter_app/test/features/subscription/`
