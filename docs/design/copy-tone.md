---
title: AgathaTrack copy and tone
owner: Documentation Team
audience: product, design, engineering, content
status: active
last_updated: 2026-09-09
tags: [design, ui, ux, brand, copy]
---

# AgathaTrack copy and tone

Everyday UI work: follow the voice summary in `.cursor/rules/design.mdc`. Use this file for `/ui-design-deep` or copy/branding tasks.

This document defines **how AgathaTrack sounds** when it communicates with pet parents and other people involved in care.

**Canonical elsewhere:**

- Product values and direction → [`true-north.md`](./true-north.md)
- Relationship and role language → [`terminology.md`](./terminology.md)
- CIM behaviour → [`care-intelligence.md`](../domains/pet_care/features/care-intelligence.md)
- Progression behaviour → [`care-progression.md`](../domains/pet_care/features/care-progression.md)

Shelter and Fostering are frozen domains — not inputs into current brand, tone, or terminology. Preserved Shelter branding rules: [`shelter-branding.md`](../engineering/frozen-domains/shelter-branding.md).

## Brand position

AgathaTrack coordinates care calmly; it should feel like a trusted companion in how it speaks — not like a taskmaster or engagement app.

The product helps carry some of the practical and emotional load of care: planning, remembering, adapting, handing over, noticing what matters, and feeling reassured when care is already well organised.

AgathaTrack should never create anxiety in order to drive engagement.

## Core voice principles

### Assume commitment, not negligence

Start from the assumption that pet parents are already trying to do right by their pets.

Do not imply forgetfulness, carelessness, likely failure, or lack of concern merely because circumstances changed.

Prefer:

- “You’ll be away next week. Would it help to review what falls during those dates?”
- “Luna’s tablets are due while you’re away. Want to make a simple care plan for that time?”

Avoid:

- “Who’ll be handling Luna’s tablets?”
- “Don’t forget Luna’s medication.”
- “You may miss some care while you’re away.”

### Reassure before prompting

Reassurance is a cardinal AgathaTrack value.

Where the system knows that care is already covered, say so clearly and stop. Do not invent another task simply to create interaction.

Prefer:

- “All covered.”
- “Everything due during those dates is already taken care of.”
- “Part of Luna’s regular care.”

Only make reassuring claims when the underlying facts support them. When coverage is incomplete or uncertain, reassure through support rather than false certainty.

### Support over judgment

Offer help, options, and clarity. Do not grade, shame, scold, moralise, or imply that care quality can be inferred from app activity.

Good care can include delayed, skipped, paused, adapted, or rescheduled routines.

### Care over engagement

AgathaTrack should reward care, not attention.

Do not manufacture reasons to open the app. Do not use streaks, XP, celebratory loops, or praise for logging.

Silence is valid product behaviour.

### Reduce mental load

Every message should make the next step clearer, easier, or more reassuring.

Do not add another concern unless the information is genuinely useful.

### Recognise invisible effort

Pet care can involve planning, disrupted sleep, worry, appointments, medication routines, handovers, expense, uncertainty, and emotional energy.

AgathaTrack may acknowledge that effort quietly and sincerely.

Avoid sentimentality, melodrama, exaggerated praise, or emotional manipulation.

### Continuity over perfection

A single disruption should not be framed as failure.

Prefer language that recognises long-term care continuity rather than perfect execution.

### Context over generic advice

Where trusted context exists, use it to make care more relevant.

Context may include travel, holidays, temporary care arrangements, environmental conditions, or changes in routine.

Do not infer sensitive personal circumstances or speculate about likely failure.

### Safety without alarmism

AgathaTrack does not avoid difficult information when it matters.

When evidence supports a meaningful care or safety review, be clear, specific, proportionate, and actionable.

Do not diagnose, overstate certainty, or use fear to force action.

### Pet parent intent over system assumptions

Agatha may suggest; the pet parent remains in control unless an existing deterministic care obligation already applies.

Agatha is the product voice for explainable support and suggestions. It is not a simulated person, veterinarian, or omniscient assistant.

Relationship terminology: [`terminology.md`](./terminology.md).

## Copy test

Before shipping a message, ask:

> Will this message make a caring pet parent feel more supported, more reassured, or more able to act — without adding unnecessary worry?

If the answer is no, reconsider whether the message should exist.

Necessary concern is not the same as unnecessary worry. Safety-relevant information should still be communicated clearly when supported by evidence.

## Tone by context

| Context | Do | Don't |
|---------|-----|-------|
| **Operational** (forms, deletes, errors, schedules) | Direct, specific, calm | Puns, emoji, pet jokes, vague startup-speak |
| **Supportive** (onboarding, empty states, confirmations) | Warm, brief, reassuring | Cute, childish, emotionally manipulative |
| **Status** (due, overdue, complete) | Plain, factual labels | Moral framing, blame, anthropomorphic panic |
| **Context change** (travel, holidays, routine disruption, weather, handover) | Assume care and offer practical support | “Don’t forget…”, “Who will handle it?”, implied failure |
| **Progression / milestones** | Recognise meaningful care continuity in a restrained way | Scores, streaks, badges, app-usage praise |
| **Safety / intelligence** | Calm, specific, evidence-bounded | Diagnosis, alarmism, unsupported certainty |
| **Care effort / emotional support** | Acknowledge effort sparingly and sincerely | Guilt, over-praise, sentimentality |
| **Legal / privacy** | Plain, precise, unambiguous | Warmth padding, metaphor, playful language |

Operational severity is allowed. Labels such as “Overdue”, “Due today”, or “Needs attention” can be appropriate when they describe a care or workflow state. Avoid language that describes the person as behind, failing, careless, or irresponsible.

### Examples (from `app_en.arb`)

| Key | Good (keep this register) | Bad (do not introduce) |
|-----|---------------------------|-------------------------|
| `deleteEntryConfirm` | “Are you sure you want to delete this entry?” | “Oops! Say goodbye to this entry 🐾” |
| `noPetsYet` | “No pets yet” | “Your fur family is waiting to be discovered!” |
| `overdue` | “Overdue” | “Uh-oh, someone's behind!” |
| `appTagline` | Calm, purpose-led (see ARB) | Exclamation-heavy marketing hype |

## Practical copy patterns

### Context-aware prompts

When circumstances change, offer help without implying the pet parent is unprepared.

Prefer:

- “You’ll be away next week. Would it help to review what falls during those dates?”
- “Luna’s regular care continues during your trip. Want to review it together?”
- “Everything due during those dates is already covered.”

Avoid:

- “Don’t forget Luna’s medication.”
- “Who’ll be handling Luna’s care?”
- “You may miss some care while you’re away.”

### Reassurance

Where the system can confidently show that care is covered, say so and stop.

Prefer:

- “All covered.”
- “Luna’s regular care is already in place for those dates.”
- “Nothing due during your trip needs attention right now.”

Avoid reassurance that exceeds the available evidence.

### Progression

Progression recognises care, not app usage.

Prefer:

- “Established”
- “Part of Luna’s regular care.”
- “A little milestone”
- “Luna’s regular weight monitoring is now part of her routine care.”

Avoid:

- “4-month streak”
- “You earned a badge”
- “Great job logging every week!”
- “Level up”

### Safety and suggestions

Prefer:

- “This change may be worth reviewing with your vet.”
- “There has been enough change in Luna’s recent weight pattern to make a review worth considering.”

Avoid:

- “Warning!”
- “Something is wrong.”
- “Agatha detected a health problem.”

## Silence

Do not surface a message when:

- context is weak or speculative;
- nothing useful changes for the pet parent;
- the only purpose is to increase engagement;
- the message would add worry without improving care;
- a lower-priority message would compete with a more important safeguard.

Detailed behavioural rules: [`care-intelligence.md`](../domains/pet_care/features/care-intelligence.md) §Silence principle.

## Landing and auth (Pet Care)

- Use **AgathaTrack** as the product name. **AgathaCheck** is legacy — do not introduce in new work.
- Landing speaks to Pet Care: calm, practical, reassuring — not cute. See [`terminology.md`](./terminology.md) for relationship language.
- Keep the login path **role-neutral**. Do not ask users to choose audience type before sign-in. Care context belongs inside the authenticated experience.
- Prefer short supporting copy over feature lists or role-based marketing gates. The form should make the next action obvious: sign in or create an account.
- Preserve email/password, validation, localization, accessibility, and native web password-manager behaviour on web. See `.agents/memory/flutter-web-password-managers.md`.

## Localization

All user-facing strings belong in ARB/l10n.

Localize enum `.label` when touched — `.agents/memory/localization-enum-labels.md`.

Do not assume English relationship vocabulary maps cleanly into other languages. Preserve intent and tone, not literal phrasing. See [`terminology.md`](./terminology.md).

## Cross-domain boundaries

This document defines voice and wording.

Behavioural rules remain canonical in the relevant domain documents. If this guide and a domain rule ever appear to conflict, the domain rule controls behaviour and this guide controls wording.
