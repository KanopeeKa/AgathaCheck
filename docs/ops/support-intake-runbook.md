---
title: Support intake operations runbook
owner: Documentation Team
audience: both
status: active
last_updated: 2026-11-14
tags: [ops, customer_support, support-intake]
---

# Support intake operations runbook

Operator guide for **Phase 1** private support intake. Canonical product rules: [support-ticketing.md](/docs/domains/customer_support/features/support-ticketing.md). **Never store secret values in this file** — names only.

## Repositories and board

| Item | Value |
|------|--------|
| Support issues repo | **AgathaTrack/AgathaTrackPrivate** (private; support requests only) |
| Engineering repo | **AgathaTrack/AgathaTrack** (public; no user text from support) |
| Support board | [@ATSupport](https://github.com/orgs/AgathaTrack/projects/1) (org project) |
| Issue feed | Built-in auto-add: repo AgathaTrackPrivate, filter `is:issue` — **confirmed**. No `actions/add-to-project` workflow and no board PAT unless auto-add later fails (record risk first). |
| Pawpet engineering board | [Pawpet](https://github.com/orgs/AgathaTrack/projects/2) — engineering issues only; support issues must not appear there |

## Server environment (names only)

| Variable | UAT | Production |
|----------|-----|------------|
| `SUPPORT_GITHUB_REPO` | `AgathaTrack/AgathaTrackPrivate` | Same slug |
| `SUPPORT_GITHUB_TOKEN` | Fine-grained PAT name: `agathatrack-support-uat` | `agathatrack-support-prod` |
| `SUPPORT_REPLY_TO` | `support@agathatrack.com` (set before receipt smoke tests) | Same |
| `APP_ENV` | `uat` | `production` |

Tokens are fine-grained, scoped to **AgathaTrackPrivate** only (Issues read/write). They can create, edit, and label; they **cannot delete issues** (redaction replaces content; an org admin deletes manually).

Do not use `NODE_ENV` as the production/uat signal for support labelling — use `APP_ENV`.

Local dev / tests: leave `SUPPORT_GITHUB_REPO` empty so GitHub outbox rows stay `disabled`.

## @ATSupport board columns

| Column | Meaning | Moved by |
|--------|---------|----------|
| New | New issue from auto-add | Automatic |
| Triaged | Read; fix `category:*` if needed; set priority | Operator |
| Waiting on user | Emailed for more information | Operator |
| In progress | Handled directly or engineering link filled | Operator |
| Engineering done | Linked AgathaTrack issue closed or fix deployed; user not told yet | Operator (later phase may automate) |
| Done | User told by email; issue closed | Automatic on close |

## Labels (AgathaTrackPrivate)

- `category:bug`, `category:suggestion`, `category:account`, `category:billing`
- `env:uat`, `env:production`, `env:unknown`
- `source:form`, `source:email`
- `priority:high`, `priority:normal`, `priority:low`
- `redacted` (after erasure/retention redact — see below)

**No `support` label** — every issue in this repo is a support request.

## Saved views

| View | Filter / intent |
|------|-----------------|
| Triage | Status New or Triaged, grouped by category |
| Waiting on user | Column Waiting on user |
| Handed to engineering | **Engineering issue** project field is set |
| Redacted: delete | `label:redacted` — delete these issues within 7 days |
| From email | `label:source:email` |

## Engineering issue template (AgathaTrack)

Create manually in **AgathaTrack/AgathaTrack** when handing work to engineering. Copy into `.github/ISSUE_TEMPLATE/` is **out of plan scope** — paste from here until a separate PR adds the file.

**Title:** `Support ref AT-XXXXXXXX — <short technical title>`

**Body:**

```markdown
## Support reference

AT-XXXXXXXX (category: <bug|suggestion|account|billing>)

## Technical summary

<!-- Operator or agent: sanitised reproduction and impact only. No reporter name, email, screenshots, or verbatim user narrative. -->

## Links

- Private support issue: **do not paste URL or body** — use the AT- reference only in AgathaTrack.
- Engineering issue URL: fill the **Engineering issue** field on the @ATSupport card after creation.

## Acceptance

<!-- What “done” means for engineering. -->
```

After creation, put the AgathaTrack issue URL in the card's **Engineering issue** field on @ATSupport.

## Redacted issues (D-009)

When retention or account erasure runs, the worker replaces the GitHub issue title and body with `[removed]` and adds `label:redacted`.

1. Open the **Redacted: delete** saved view.
2. **Delete each redacted issue within 7 days** (org owner or repo admin on **AgathaTrackPrivate**; support API tokens cannot delete).
3. Deletion removes issue comments and edit history — required to finish erasure on GitHub.

Until you delete the issue, original text may remain in GitHub edit history.

**Agent comments** on a support issue may contain personal data. They are removed **only when you delete the redacted issue**, not when the issue is merely redacted.

## Hand-created `source:email` issues

Email that bypasses the web form: create an issue in AgathaTrackPrivate with template **Support request from email** (default label `source:email` only).

- No Postgres ticket row — retention is manual on a 12-month clock.
- Erasure requests for these issues: handle manually (redact + delete per D-009).
- Board auto-add still applies.

## Staff access

Grant `users.is_support_staff` only via:

```bash
cd server && node scripts/support_staff.js grant --email <account>
cd server && node scripts/support_staff.js revoke --email <account>
```

Run after the Phase 3 migration on each environment. Staff read tickets at `/staff/support` (no menu entry).

## Prerequisites checklist (operator)

- [ ] AgathaTrackPrivate private; labels including `env:unknown` and `redacted`; no `support` label
- [ ] @ATSupport columns and workflows (item added → New; item closed → Done)
- [ ] Engineering issue text field and saved views above
- [ ] Tokens `agathatrack-support-uat` / `agathatrack-support-prod` in GitHub environments (**values** in secrets UI only)
- [ ] `pawpet-bot` collaborator on AgathaTrackPrivate
- [ ] Watching AgathaTrackPrivate issues
- [ ] Mailboxes: `support@`, `legal@`, `partnerships@` (plus existing `contact@`)
- [ ] Smoke test: manual issue → New; close → Done; pawpet board unchanged; delete test issue

## Related debt (GitHub issues)

Track implementation gaps opened during plan phase 1:

- Screenshot re-encoding / metadata stripping (`sharp`) — [#2301](https://github.com/AgathaTrack/AgathaTrack/issues/2301).
- `listProjectIssues` in `.github/scripts/github-project-lib.js` (first 100 items, no repository filter) — [#2302](https://github.com/AgathaTrack/AgathaTrack/issues/2302).
