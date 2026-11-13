# Support intake phase 1

## Goal
Ship the Phase 1 contact hub and private support intake from KanopeeKa/AgathaCheck#2271: an EN/FR hub, a private Postgres ticket, one receipt email, and a GitHub issue in the private repo AgathaTrackPrivate that lands on @ATSupport (`users/KanopeeKa/projects/4`) by built-in auto-add. Auto-add is confirmed. Do not add a board token, an Actions add-to-project workflow, or a `support` label. Issues never go in public AgathaCheck. The driver merges this plan; phase workers push their phase branch only.

## Phases

### Phase 1 — Canonical spec and runbook
```json
{
  "allowed_paths": [
    "docs/domains/customer_support/**",
    "docs/ops/prod-backup-restore-plan.md",
    "docs/ops/support-intake-runbook.md",
    "flutter_app/assets/legal/en/privacy-notice.md",
    "flutter_app/assets/legal/fr/politique-de-confidentialite.md"
  ],
  "forbidden_paths": [".github/**"],
  "allowed_exceptions": ["docs"],
  "companions": [],
  "exit_checklist": [
    "canonical support-ticketing sections replaced from issue 2271",
    "runbook and backup-plan line present",
    "two debt issues linked from the PR body"
  ]
}
```
Scope: replace, do not append, the Summary, requirement tables, acceptance table, Out of scope, Still open, and decision log in `docs/domains/customer_support/features/support-ticketing.md` with the body of issue #2271. Close the Brevo and admin-role open points (D-011, D-005). Fix `docs/domains/customer_support/changes/support-roadmap.md`: §4.2 has no separate privacy address, §11 has no customer ticket view in Phase 1, and the later GitHub phase automates handover D-010 rather than creating the first private issue. Add `docs/ops/support-intake-runbook.md` with token names only (never values), UAT and production settings, board columns, labels, saved views, the Engineering-issue template text, the 7-day owner deletion of `redacted` issues, hand-created `source:email` issues (12-month deletion and manual erasure), and the note that agent comments are removed only when that issue is deleted. Add one line to step 1 of `docs/ops/prod-backup-restore-plan.md`: when `scripts/ops/backup.sh` is written it must include the private screenshot folder as its own root, because that folder sits outside `uploads/`. Add a short paragraph to both privacy notices: GitHub (AgathaTrackPrivate) is a processor, redaction replaces the title and body with `[removed]`, and the owner deletes the redacted issue within 7 days. Open two debt issues and link them from the PR: screenshot re-encoding with `sharp`, and `listProjectIssues` in `.github/scripts/github-project-lib.js` (first 100 items, no repository filter).
Out of scope: `.github/**` (the issue template cannot be copied into `.github/ISSUE_TEMPLATE/` by this plan), product code, migrations, and any secret value.

### Phase 2 — Contact hub
```json
{
  "allowed_paths": [
    "flutter_app/lib/features/support/hub/**",
    "flutter_app/lib/features/experience/presentation/screens/account_screen.dart",
    "flutter_app/lib/features/experience/presentation/utils/drawer_menu_actions.dart",
    "flutter_app/lib/features/experience/presentation/config/drawer_menu_config.dart",
    "flutter_app/lib/core/widgets/legal_footer_links.dart",
    "flutter_app/lib/core/legal/legal_document_id.dart",
    "flutter_app/lib/core/router/app_router.dart",
    "flutter_app/lib/features/auth/presentation/widgets/landing/landing_operations_desk_page.dart"
  ],
  "forbidden_paths": [],
  "allowed_exceptions": ["tests", "docs"],
  "companions": [
    "flutter_app/lib/l10n/app_localizations.dart",
    "flutter_app/lib/l10n/app_localizations_en.dart",
    "flutter_app/lib/l10n/app_localizations_fr.dart"
  ],
  "approved_sensitive_paths": [
    "flutter_app/lib/features/auth/presentation/widgets/landing/landing_operations_desk_page.dart"
  ],
  "exit_checklist": [
    "signed-out landing footer opens the hub",
    "account mailto row removed and drawer_contact deleted",
    "flutter analyze and hub tests green"
  ]
}
```
Scope: R-001, R-002, R-003, R-004 and the hub slice of R-020 and R-021 from the canonical doc. One-column hub at `/contact`, public in the router allowlist, linked from the Account row and from the landing footer (`LegalFooterLinks` imported by the landing page). Cards: Help & Support (route registered here; the form screen arrives in phase 4), Partnerships and Legal & Privacy via `launchExternalLink` with the copy dialog, and a general line for `contact@agathatrack.com`. Addresses shown: `contact@`, `support@`, `legal@`, `partnerships@`. Delete the dead `drawer_contact` case. EN and FR strings in the arb files.
Out of scope: the form, screenshots, any other file under `features/auth/`, and the submit API.

### Phase 3 — Ticket submit API and tables
```json
{
  "allowed_paths": [
    "db/migrations/**",
    "server/scripts/migrations/**",
    "server/routes/support/tickets.js",
    "server/lib/support/submit/**",
    "server/lib/support/schema/**"
  ],
  "forbidden_paths": ["server/routes/auth/**", "server/lib/auth/**"],
  "allowed_exceptions": ["tests", "docs"],
  "companions": ["server/bin/server.js"],
  "approved_sensitive_paths": ["db/migrations/**"],
  "exit_checklist": [
    "migration applies and rolls back",
    "submit tests cover 401, signed-in email, and 429",
    "OpenAPI support contract validates"
  ]
}
```
Scope: R-005, R-006, R-009, R-010 and R-018. One migration creates `support_tickets`, `support_attachments`, `support_outbox`, and `users.is_support_staff` (boolean, default false). Generate UUIDs in application code; do not call `gen_random_uuid()`. Outbox rules: `ticket_id` required for `receipt` and `github_issue`, empty for `github_issue_delete`; `github_issue_number` required for delete rows (database check); unique `(ticket_id, kind)` for receipt and create-issue; unique `(kind, github_issue_number)` for delete rows. Mount `POST /api/support/tickets` and `/backend/api/support/tickets` from `server/bin/server.js` only. Sign-in is decided in the handler: no bearer means signed out; an invalid or expired bearer returns 401; a signed-in receipt uses `users.email` and ignores a body address. `publicAccessGate` already returns 403 in coming-soon mode before the handler. Text-only bodies may be JSON. If a file part is present, call `server/lib/support/submit/screenshot_gate.js`, which this phase implements as a rejection (phase 6 replaces that behaviour). Limits are SQL counts: signed in, 3 per hour and 10 per 24 hours per account; signed out, 3 per hour per `req.ip` and 5 per 24 hours per normalised email (lower case, `+tag` removed). 429 includes `Retry-After`. Do not add a custom `express-rate-limit` key that reads `req.ip` without `ipKeyGenerator`. Field limits: title 120, description 5000, steps 3000, expected and actual 2000, email 254. Reference is `AT-` plus 8 Crockford base32 characters. Add `docs/architecture/openapi/support-tickets.json` (fixed companion) and do not fold it into `pet-care-critical.json`.
Out of scope: receipt sending, GitHub calls, staff routes, screenshot storage, erasure, and any file under `auth/`.

### Phase 4 — Support form
```json
{
  "allowed_paths": [
    "flutter_app/lib/features/support/form/**",
    "scripts/ci/verify-web-artifact.sh"
  ],
  "forbidden_paths": [],
  "allowed_exceptions": ["tests", "docs"],
  "companions": [
    "flutter_app/lib/core/router/app_router.dart",
    "flutter_app/lib/l10n/app_localizations.dart",
    "flutter_app/lib/l10n/app_localizations_en.dart",
    "flutter_app/lib/l10n/app_localizations_fr.dart"
  ],
  "exit_checklist": [
    "verify-web-artifact asserts version.json",
    "form error-summary and bug-field tests green",
    "flutter analyze green"
  ]
}
```
Scope: R-006, R-007 and the form slice of R-020 and R-021. The form posts to the phase 3 endpoint. Categories `bug`, `suggestion`, `account`, `billing`. Bug fields (expected, actual, steps, frequency `always|sometimes|once`) appear without moving focus. Errors sit on the fields; a failed submit moves focus to an error summary; success announces the reference and offers copy. Version and build come from `GET /version.json` at the site root with a cache-busting query, and stay empty when the response is missing or not JSON. Do not read the About-screen version string and do not add `package_info_plus`. Platform on web is `web`. Browser family is a coarse match on `navigator.userAgent` through `package:web`. Context sent to the server is the R-007 allowlist only. `scripts/ci/verify-web-artifact.sh` fails the web build when `version.json` is absent beside `index.html`. Wire the form route in `app_router.dart` (companion).
Out of scope: screenshot controls (phase 6), hub layout (phase 2), and the server.

### Phase 5 — Staff flag and read-only queue
```json
{
  "allowed_paths": [
    "server/scripts/support_staff.js",
    "server/lib/support/staff/**",
    "server/routes/support/staff.js",
    "flutter_app/lib/features/support/staff/**"
  ],
  "forbidden_paths": ["server/routes/auth/**", "server/lib/auth/**", "server/routes/profile/**"],
  "allowed_exceptions": ["tests", "docs"],
  "companions": [
    "server/bin/server.js",
    "flutter_app/lib/core/router/app_router.dart",
    "flutter_app/lib/l10n/app_localizations.dart",
    "flutter_app/lib/l10n/app_localizations_en.dart",
    "flutter_app/lib/l10n/app_localizations_fr.dart"
  ],
  "exit_checklist": [
    "non-staff staff API returns 403",
    "grant and revoke script covered by a test",
    "staff flag absent from profile and token code"
  ]
}
```
Scope: D-005 and R-014. `users.is_support_staff` already exists from phase 3. `server/scripts/support_staff.js` grants and revokes it. The flag is not added to profile fields, the profile response, or access tokens. Staff routes look the flag up on each request. `GET /api/support/staff/tickets` and `GET /api/support/staff/tickets/:id`, also under `/backend`, list tickets and show blocked or failed outbox rows. No reply, assign, or close. Flutter screen `/staff/support` has no drawer or menu entry. A non-staff caller gets 403.
Out of scope: attachment bytes (phase 6), profile and auth modules, and GitHub writes.

### Phase 6 — Private screenshots
```json
{
  "allowed_paths": [
    "server/lib/support/screenshots/**",
    "server/routes/support/attachments.js",
    "server/lib/jobs/handlers/fileDelete.js",
    "flutter_app/lib/features/support/screenshots/**"
  ],
  "forbidden_paths": [],
  "allowed_exceptions": ["tests", "docs"],
  "companions": [
    "server/bin/server.js",
    "server/lib/support/submit/screenshot_gate.js",
    "flutter_app/lib/l10n/app_localizations.dart",
    "flutter_app/lib/l10n/app_localizations_en.dart",
    "flutter_app/lib/l10n/app_localizations_fr.dart"
  ],
  "exit_checklist": [
    "signed-out upload rejected",
    "non-staff and guessed-id attachment GET return 403",
    "screenshot keyboard controls tested in both languages"
  ]
}
```
Scope: R-008 and the screenshot slice of R-021. Signed-in senders only, at most 3 files, 2 MB each, 6 MB total, PNG JPEG or WebP via `safeUpload` content sniffing. Store outside `uploads/` under a new `fileDelete.js` storage key, with generated file names. `GET /api/support/attachments/:id` (and `/backend`) returns 403 for anyone who is not staff before looking up the id, and 404 for staff when the id is missing. The form shows a notice about personal information before upload. Keyboard-operable add and remove controls. Replace the phase 3 rejection in `screenshot_gate.js` so the submit route stores files. Do not serve the folder from `express.static`. Re-encoding stays on the debt issue from phase 1; do not add `sharp` here.
Out of scope: retention deletes (phase 8), the public uploads tree, and `package:file_type` or other new dependencies.

### Phase 7 — Receipt and GitHub outbox
```json
{
  "allowed_paths": [
    "server/lib/support/outbox/**",
    "server/lib/email/i18n.js",
    "server/services/mailService.js",
    "server/config/mail.js"
  ],
  "forbidden_paths": [],
  "allowed_exceptions": ["tests", "docs"],
  "companions": ["server/lib/jobs/cleanupJobsRunner.js"],
  "exit_checklist": [
    "receipt subject covered in EN and FR",
    "public-repo startup check blocks create-issue rows",
    "write-back after a deleted ticket queues a redact row"
  ]
}
```
Scope: R-016, R-017, D-006 and D-008. Drain the outbox from the existing cleanup poll in `cleanupJobsRunner.js`. Use Node `fetch` for GitHub. Create-issue title `[AT-XXXXXXXX] <category>: <title>`. Body fences the reporter's words as untrusted and adds only the allowlisted context. Labels: `category:*` copied from the stored category, `env:<APP_ENV>` or `env:unknown`, `source:form`. No `support` label and no priority label from the server. Receipt subject EN `[AT-XXXXXXXX] We received your request`, FR `[AT-XXXXXXXX] Nous avons reçu votre demande`, same language as the body, via `resolveEmailLocale`. Reply-To is `SUPPORT_REPLY_TO`. The body does not repeat the user's text. Before a receipt or create-issue row runs, re-read the ticket and skip the row when the ticket is gone. Redact rows run from the stored issue number and do not need a ticket. If writing the issue number back finds the ticket gone, insert a `github_issue_delete` row for that number. Statuses: pending, sent, failed, blocked, disabled, with backoff and a terminal attempt cap. Empty `SUPPORT_GITHUB_REPO` leaves rows `disabled`. Startup treats a non-200 or a repo whose `private` is not true as `blocked`, and returns those blocked create-issue rows to `pending` when a later check passes. HTTP 422 for a missing label is a configuration failure, not a hot retry. `last_error` never contains ticket text. Do not key the privacy check on `NODE_ENV`.
Out of scope: deleting GitHub issues (no token can), board field updates, the retention sweep, and `.github` workflows. Built-in auto-add places the issue on @ATSupport; this phase does not call a projects API.

### Phase 8 — Retention, erasure, and export
```json
{
  "allowed_paths": [
    "server/lib/support/retention/**",
    "server/lib/account/accountErasureService.js",
    "server/lib/gdprUserExport.js"
  ],
  "forbidden_paths": ["server/routes/auth/**", "server/lib/auth/**"],
  "allowed_exceptions": ["tests", "docs"],
  "companions": ["server/lib/jobs/cleanupJobsRunner.js"],
  "exit_checklist": [
    "erasure test keeps issue numbers and screenshot paths",
    "export includes signed-out tickets with the same normalised email",
    "retention hook is once per UTC day"
  ]
}
```
Scope: R-019 and D-009. Daily `support_retention` on `scheduler_daily_runs`, invoked from the cleanup poll, same order as erasure. Inside `acceptAccountErasure`, before the user row is deleted: (1) select the account's tickets plus signed-out tickets whose `reporter_email_normalised` equals the account email normalised the same way (lower case, `+tag` removed); (2) capture screenshot paths and issue numbers; (3) enqueue existing `file_delete` jobs for those paths and insert `github_issue_delete` outbox rows with a null ticket id and a required issue number; (4) delete pending receipt and create-issue outbox rows for those tickets; (5) delete the tickets so attachment rows cascade. The redact row replaces the GitHub title and body with `[removed]` and adds `redacted`. Do not put ticket text in `cleanup_jobs` payloads. Extend `GET` export in `gdprUserExport.js` with the same email match. Do not add a `cleanup_jobs` job type. Hand-created `source:email` issues have no ticket row; the runbook already assigns those to the owner.
Out of scope: a new cleanup job type, GitHub issue deletion, auth routes, and the backup script (the draft plan only records the folder).

## Proof on UAT
On https://uat.agathatrack.com a signed-out visitor opens Contact from the landing footer, submits a bug report, and sees an `AT-` reference. The receipt arrives from the UAT mailbox with Reply-To `support@agathatrack.com`. A new issue appears in AgathaTrackPrivate and on @ATSupport in New, with no issue created in AgathaCheck. A staff account can open `/staff/support` and the screenshot; a normal account receives 403. Submitting with `SUPPORT_GITHUB_REPO` pointed at a public repo leaves the create-issue row blocked and creates nothing.
