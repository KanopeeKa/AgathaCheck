---
title: Notifications v2 programme
owner: Product
audience: both
status: active
last_updated: 2026-10-04
tags: [domain, notifications, programme]
domain: notifications
---

# Notifications v2 programme

**Canonical spec:** [notifications-v2-spec.md](../features/notifications-v2-spec.md) (accepted rev 2.3 → **2.3.1** via foundation plan).

**Execute-plan roadmap:** `.agents/plans/notifications-v2-roadmap-7f3b.md`

## Goal

Ship Notifications v2 (Activity / For you, care out of inbox, relationship + account + Agatha) per the accepted spec. **PR8 (subscription)** stays blocked until a billing provider and server entitlement source exist.

## Integration branch

After foundation merges spec/docs to `main`:

```text
cursor/notifications-v2-integration-7f3b  ← PR1–PR7 merge here
        └── one final PR → main (/babysit-uat)
```

## Child plans (order)

| # | plan_id | Spec PR | Outcome |
|---|---------|---------|---------|
| 0 | `notifications-v2-foundation-7f3b` | — | Rev **2.3.1** doc fixes + merge `claude/jolly-allen-cxrzgc` lineage to `main` |
| 1 | `notifications-v2-pr1-7f3b` | PR1 | Stop due/overdue inbox rows; migration archive + reclassify; client kind parser; BDD v2 bootstrap |
| 2 | `notifications-v2-pr2-7f3b` | PR2 | Two-tab inbox, calm badge, explainer, Appendix A FAQ in ARB |
| 3 | `notifications-v2-pr3-7f3b` | PR3 | Relationship emitters, §3.4 map, ban `general`, `shareLinkFollowed` |
| 4 | `notifications-v2-pr4-7f3b` | PR4 | Inline actions (core); grouping + R4/R18 optional tier |
| 5 | `notifications-v2-pr5-7f3b` | PR5 | Server suggestions S1–S7 |
| 6 | `notifications-v2-pr6-7f3b` | PR6 | Settings matrix (core); digest/email (enhancement tier) |
| 7 | `notifications-v2-pr7-7f3b` | PR7 | Security A1–A3, A6 + device label + Secure my account |
| — | `notifications-v2-pr8-7f3b` | PR8 | **Skipped** — billing provider undecided |
| 8 | `notifications-v2-integration-7f3b` | — | Integration → `main`, pre-UAT |

## Cut order (time pressure)

1. PR6 enhancements (digest/email)  
2. PR4 enhancements (grouping, R4/R18)  
3. Never cut PR7 security core or PR1 migration correctness  

## References

- Decisions: [notification-decisions.md](../features/notification-decisions.md) §C  
- Deferred: [deferred.md](./deferred.md)  
- Security note (before PR7 code): `docs/domains/notifications/changes/notifications-v2-security-architecture.md` (created in PR7 plan phase 1)
