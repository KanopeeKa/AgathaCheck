---
title: AgathaTrack True North
owner: Documentation Team
audience: product, design, engineering, content
status: active
last_updated: 2026-09-09
tags: [design, brand, product]
---

# AgathaTrack True North

This document defines **why** AgathaTrack behaves the way it does. It is the product centre of gravity for the active MVP.

**Related (how it sounds and what words to use):**

- Voice and tone → [`copy-tone.md`](./copy-tone.md)
- Relationship and role language → [`terminology.md`](./terminology.md)
- Visual personality and layout → [`principles.md`](./principles.md)

Shelter and Fostering are **frozen** domains — preserved in Git, not inputs into current brand, terminology, tone, or product direction. See [`frozen-domains`](../engineering/frozen-domains/README.md).

## Product direction

```
AgathaTrack True North
  → Pet Care (active MVP)
  → Subscription / future Pet Sitting / integrations / other active domains

Shelter + Fostering
  → preserved frozen domains
  → not inputs into current True North
```

## Two layers (function and voice)

AgathaTrack **coordinates care calmly**; it should **feel like a trusted companion** in how it speaks — not like a taskmaster or engagement app.

| Layer | What it means |
|-------|----------------|
| **Coordination** | Dependable, humane, efficient care coordination for all-day use — planning, remembering, adapting, handing over, noticing what matters |
| **Companion voice** | Calm, trusted, supportive language that reduces mental load and assumes commitment |

Neither layer contradicts the other. Coordination is what the product does; companion tone is how it should feel when it communicates.

## Core values

These values govern product behaviour and copy. Wording patterns live in [`copy-tone.md`](./copy-tone.md); behavioural semantics live in domain docs.

1. **Assume commitment, not negligence** — pet parents are already trying to do right by their pets.
2. **Reassure before prompting** — when facts support it, say care is covered and stop. When uncertain, reassure through support, not false certainty.
3. **Support over judgment** — offer help and clarity; do not grade, shame, or moralise.
4. **Care over engagement** — reward care, not attention. No streaks, XP, or manufactured reasons to open the app.
5. **Continuity over perfection** — a single disruption is not failure; recognise long-term care continuity.
6. **Context over generic advice** — use trusted context; do not speculate about sensitive circumstances.
7. **Reduce mental load** — every message should clarify the next step or reassure; do not add worry without benefit.
8. **Recognise invisible effort** — acknowledge planning, worry, coordination, and emotional energy quietly and sincerely.
9. **Safety without alarmism** — communicate meaningful care or safety information clearly when evidence supports it; do not diagnose or use fear to force action.
10. **Pet parent intent over system assumptions** — Agatha may suggest; the pet parent remains in control unless a deterministic care obligation already applies.
11. **Silence is valid** — absence of a message is often correct. Do not surface copy merely to drive engagement.

## Documentation hierarchy

| Layer | Canonical home | Owns |
|-------|----------------|------|
| True North | This file | Why — values and product direction |
| Terminology | [`terminology.md`](./terminology.md) | Pet parent, care team, legal terms, l10n rules |
| Copy tone | [`copy-tone.md`](./copy-tone.md) | How the product sounds — register, patterns, examples |
| Care Intelligence | [`care-intelligence.md`](../domains/pet_care/features/care-intelligence.md) | CIM silence, evidence bounds, safeguards, suggestions |
| Care Progression | [`care-progression.md`](../domains/pet_care/features/care-progression.md) | Established, milestones, anti-gamification |
| Care Planning | domain docs | Deterministic Care Status and obligations |
| Frozen Shelter/Fostering | [`frozen-domains`](../engineering/frozen-domains/) | Preserved guidance including org branding |

If copy-tone and a domain rule appear to conflict, **the domain rule controls behaviour** and **copy-tone controls wording**.
