---
title: Authentication journeys
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
tags: [domain,auth,journeys]
---

# Authentication journeys

User-facing auth and profile flows in AgathaTrack (see `authentication.feature`).

## Sign up

Guardians register with email and password (minimum six characters). Validation covers mismatched passwords, missing email, invalid email format, duplicate email, and password rules.

## Log in

Email/password login with incorrect-password and unknown-email errors. Password visibility toggle on the login form.

## Log out

Session ends from the app; subsequent API calls require re-authentication.

## Profile

View account details and update profile fields from the profile screen.

## Navigation between auth screens

Login ↔ sign-up navigation links on the unauthenticated shell.

---

**Lessons:** [changes/lessons.md](../changes/lessons.md) · **Specs:** [specs.md](specs.md)
