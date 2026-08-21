# Foster onboarding product rules (v1)

**Status:** Active for execute-plan `foster-front-door-v1-5a1b`  
**Canonical form:** [`regulatory/forms/default-foster-candidate-form-v1.3.xml`](../../regulatory/forms/default-foster-candidate-form-v1.3.xml)

This document captures foster-specific product rules for the v1 delivery. General platform rules remain in the uploaded product-rules reference; this file records **scope decisions** for engineering.

---

## In scope (v1)

### Foster candidate questionnaire

- One editable questionnaire template per shelter; default seed is form v1.3.
- Screening outcomes: **Go**, **Go with reservation**, **No Go** (never use “fail” in candidate copy).
- All required questions mandatory before submit.
- Result logic:
  - All screening answers Go → **AUTO_GO** (unless org enables light-touch review).
  - Any reservation or No Go → **admin review required**.
- Admin override/decision requires structured reason + audit; candidate answers are immutable (staff notes only).
- Matching profile fields (PF01–PF06) guide placement; they do not block screening by themselves.
- Multi-shelter: each shelter relationship has an independent submission.

### Home visit

- Scheduled admin event with date/time/address (address for logistics only — **never in exported reports**).
- Multiple attendees; one validator with `home_visits` permission.
- Checklist + notes + photos; outcome Yes/No with communicated reason on No.
- Reschedule and cancel supported.
- **No fake/self-validated home visit product path** — admins use standard workflow only.

### Annual revalidation

- Yearly check-in after home visit approval (or last revalidation).
- Change-of-circumstances subset questionnaire; admin may require a new home visit.

### Document bundle

- Triggers after home visit Yes; supports in-app and paper-sign admin confirmation.

### Offline foster claim

- Self-service claim invite links external record to registered account (admin merge remains fallback).

---

## Explicitly deferred (not v1)

| Area | Notes |
|------|-------|
| Pet sitter persona | No role, pack, or sitter UI |
| Duplicate medication conflict UI | Online conflict detection deferred as gold plating |
| Shelter broadcast messaging | Needs robust messaging platform later |
| Close-sit ratings / feedback | N/A while sitter deferred |

---

## Audit events (questionnaire)

From form v1.3 versioning section:

- `FOSTER_CANDIDATE_FORM_STARTED`
- `FOSTER_CANDIDATE_FORM_SUBMITTED`
- `FOSTER_CANDIDATE_PROFILE_UPDATED`
- `FOSTER_CANDIDATE_REVIEW_REQUESTED`
- `FOSTER_CANDIDATE_CLARIFICATION_REQUESTED`
- `FOSTER_CANDIDATE_ADMIN_NOTE_RECORDED`
- `FOSTER_CANDIDATE_DECISION_RECORDED`
- `FOSTER_CANDIDATE_FORM_VERSION_PUBLISHED`

---

## Data deletion

Candidates cannot self-delete questionnaire or home visit data; they may request deletion handled by admin/ops (extend GDPR tooling as needed).
