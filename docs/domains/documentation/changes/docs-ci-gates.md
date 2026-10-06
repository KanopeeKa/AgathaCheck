---
title: Spec — Documentation CI gates (canonical docs enforcement)
owner: Documentation Team
audience: both
status: in-delivery
status_since: 2026-10-06
plan: docs-ci-gates-warn-2316
folds_into: docs/domains/documentation/standards.md
last_updated: 2026-10-06
---

# Spec — Documentation CI gates

**Status:** proposed (v2.1 — second review round, incorporating Cursor's consistency pass). **Landing path:** `docs/domains/documentation/changes/docs-ci-gates.md`, in the same PR as the gates.
**Builds on:** the merged PRs #1703 (`/canonical-docs` skill, `standards.md`, template) and #1709 (Claude Code wiring).
**Folds into:** `standards.md`. When this is delivered, §3 and §4 of this spec become the "Conventions" and "Enforcement" sections there, and this file is deleted (R-A4 applies to it too).

## 0. Alignment with what is merged on `main`

This spec **adopts the merged template as the normative format**, so docs already written to it don't need to change. Where the checks need something stricter, the delivering PR updates `standards.md`, `feature-template.md` and the skill at the same time (principle P6).

| Topic | Normative (this spec) | Merged today | Action in the delivery PR |
|---|---|---|---|
| Folder | `changes/` (not `proposals/`) | same | — |
| ID prefix | `feature_id` upper-cased, `_` → `-` | same (standards rule 4) | — |
| Requirements header | `\| ID \| Rule \| Status \|` | same | — |
| Requirement status | `Live`, `In delivery`, `Planned`, **`Retired`** | no `Retired` | Add `Retired` to standards rule 4, the skill §3 and the template comment |
| AC header | `\| Given / When / Then \| Requirement \| Coverage \|` | same | — |
| Coverage format | `bdd:` / `test:` / `none — #n` / `TBD — consolidate` (§3.3) | prose (`….feature — Scenario: …`, `Coverage: none — issue #…`) | Update the template example row and the skill §3. The parser tolerates the legacy prose forms on **untouched** rows only |
| Decision status | `Live`, `Superseded by <ID>` | `Live` (template), free-text `Agreed` (legacy) | Add a closed set to standards rule 3, with the consolidate mapping `Agreed → Live` |
| `related_bdd` frontmatter | **recommended** (WARN) | required (standards rule 2) | Move to "recommended" in standards rule 2 |
| `related_prs` | advisory (WARN) | "append on merge" (rule 8) | Reword rule 8 as advisory, with `git log --follow` as the authoritative history |
| PR body | an H2 `## Docs` section, always | the skill says `Docs: N/A — …` in step 1 and `## Docs` in step 8 | The skill's step 1 becomes "write `N/A — <reason>` under `## Docs`" |

## 1. Goals and non-goals

**Goals**
1. A PR that changes behaviour cannot merge without a declared docs outcome.
2. Docs in `changes/` can't pile up: completed, superseded or frozen ones are rejected, and stale proposals are surfaced.
3. Canonical docs that have been migrated keep a stable, machine-checkable shape.
4. Acceptance criteria are traceable to BDD scenarios or tests, and coverage is visible per domain.

**Non-goals:** judging whether doc content is correct; forcing legacy docs to conform before they are consolidated; any automated write to `main`.

## 2. Design principles (normative)

| # | Principle | Consequence |
|---|---|---|
| P1 | A PR never fails because of a file it didn't touch. | Blocking rules are diff-scoped. Repo-wide findings are reported only. |
| P2 | Time-based rules never block PRs. | Age checks warn in a PR. The weekly job opens or updates an issue. |
| P3 | Legacy docs are grandfathered by a baseline that can only shrink. | `scripts/docs-legacy-baseline.json` follows the pattern of the existing ratchet files. |
| P4 | One entry script, with modular internals. | `scripts/check_docs_canonical.js` (CLI, under 150 lines) plus `scripts/lib/docs-canonical/{parse,diff,gates-pr-body,gates-changes,gates-shape,gates-ids,gates-trace,report}.js`, each under 500 lines **from the start**. |
| P5 | Messages tell the author how to fix the problem. | Each error carries the file, line, rule ID and a one-line fix pointing to the skill or `standards.md`, emitted as GitHub `::error`/`::warning` annotations. |
| P6 | No new policy without updating the policy doc. | Every rule enforces wording in `standards.md`. New wording (the `Retired` status, the closed decision-status set, change-doc frontmatter, advisory `related_*`, the Coverage forms) lands in the same PR (see §0). No existing column is renamed. |

## 3. Machine-readable conventions

### 3.1 Canonical doc frontmatter

```yaml
title: …
domain: <domain>             # must match the path (existing check)
feature_id: <snake_or_kebab> # required; source of the ID prefix
status: active
last_updated: YYYY-MM-DD
related_bdd: [...]           # recommended (WARN when missing on non-baseline docs with no `bdd:` AC row)
related_prs: [...]           # advisory, see §8
```

### 3.2 Required H2 headings (exact text)

`## Requirements` · `## Acceptance criteria` · `## Decision log`

### 3.3 Tables

| Section | Header row (exact, in order) |
|---|---|
| Requirements | `\| ID \| Rule \| Status \|` |
| Acceptance criteria | `\| Given / When / Then \| Requirement \| Coverage \|` |
| Decision log | `\| ID \| Decision \| Rationale \| Status \| Date \| PR \|` |

- **Requirement `Status`:** `Live` · `In delivery` · `Planned` · `Retired`.
- **AC `Requirement`:** one or more requirement IDs from the same doc, comma-separated.
- **AC `Coverage`, normative forms:**
  - `bdd: <file>.feature#<Scenario title>`: an exact title match after normalisation (whitespace collapsed; curly quotes and apostrophes folded to ASCII; trailing period ignored).
  - `bdd: <file>.feature@<tag>`: a Gherkin tag on the scenario. This is preferred when titles change often.
  - `test: <path>`: the whole file is the evidence. Use it only when the file covers a single behaviour; otherwise name the test.
  - `test: <path>#<test name>`: an **exact** match against the first string-literal argument of a `test(`, `it(`, `testWidgets(`, `group(` or `describe(` call in that file (Jest and Dart `flutter_test` share these call shapes). A nested test may be written `describe name > test name`. No substring matching.
  - **Examples:** `bdd: away_care_planning.feature#Changing a care date from the care item with This date only updates the next dates` · `bdd: away_care_planning.feature@away-reschedule` (a Gherkin tag on the scenario) · `test: server/test/careSchedule.test.js#skipOccurrence advances the series`.
  - `none — #<issue>`.
  - `TBD — consolidate`: allowed on untouched rows only (R-T2).
  - `<file>.feature` paths are resolved under `flutter_app/test/bdd/features/`.
- **Tolerated legacy forms (untouched rows only):** a `Coverage:` prefix, the word `issue` (as in `none — issue #12`), and prose like `` `….feature` — Scenario: <title> ``. On a touched row these are an R-T1 error, and the fix message gives the normative form.
- **Decision `Status`:** `Live` · `Superseded by <ID>`. Proposed decisions belong in `changes/`, not in the canonical log. Consolidate maps legacy `Agreed` to `Live`, and legacy dated cells (e.g. `Agreed 2026-09-12`) to `Live` with the date moved to `Date`.
- **Decision `Date`:** `YYYY-MM-DD`. **`PR`:** `#<n>` or `—`.

### 3.4 Change doc frontmatter (`changes/`)

```yaml
status: proposed | in-delivery
status_since: YYYY-MM-DD
folds_into: docs/domains/<d>/features/<capability>.md   # exists at HEAD or is added in the same PR
plan: <execute-plan id> | #<issue>                      # required when in-delivery
```

### 3.5 PR body `## Docs` section

An H2 heading `## Docs`, followed by either:
- one or more `docs/domains/*/features/*.md` paths (as bullets or comma-separated), plus optional notes on folded or deleted docs and IDs added; or
- `N/A — <reason>`.

The checkbox in the PR template is a human reminder only, and CI ignores its state. The template keeps it, with an HTML comment saying so.

## 4. Gates

Severity is **BLOCK** (the job fails, once `DOCS_GATE_MODE=block`), **WARN** (an annotation only) or **REPORT** (the job summary only).

### 4.1 Gate A — PR body declaration (`--pr-body`)

**Behaviour paths** are kept as a constant in `lib/docs-canonical/gates-pr-body.js`, with a comment pointing to the skill's decision tree:
- `flutter_app/lib/**`, excluding `*.g.dart`, `*.mocks.dart`, `*.freezed.dart` and `l10n/app_localizations*.dart`;
- `flutter_app/lib/l10n/*.arb`;
- `server/routes/**`, `server/lib/**`, `server/migrations/**`, `server/bin/**`.

These are **excluded**: `flutter_app/test/**`, `server/test/**`, `e2e/**`, `scripts/**`, `.cursor/**`, `.github/**`, `docs/**`.

| Rule | Severity | Condition | Fix message |
|---|---|---|---|
| R-A1 | BLOCK | The PR touches a behaviour path and the body has no `## Docs` H2. | "Add `## Docs`: canonical doc path(s) updated, or `N/A — <reason>`. See `/canonical-docs` Mode A." |
| R-A2 | BLOCK | `## Docs` holds an N/A whose **reason text after `N/A —`** is under 10 characters after trimming, or is a placeholder (`TODO`, `tbd`, `-`, `…`). | "Give a real reason, e.g. `N/A — refactor, no contract change`." |
| R-A3 | BLOCK | Any `features/*.md` path listed under `## Docs` is not modified in the diff. Each listed path is checked; several are allowed. | "`<path>` is listed under `## Docs` but not changed in this PR." |
| R-A4 | BLOCK | The diff deletes a `changes/` doc that has a `folds_into` in its BASE version, and that target is not modified in the diff. | "Fold `<file>` into `<folds_into>` in the same PR before deleting it." |
| R-A4b | BLOCK | The diff deletes a legacy `changes/` doc with **no** `folds_into`, and no `features/*.md` in the same domain is modified in the diff. | "Deleting `<file>` requires updating its canonical doc in the same domain in this PR." |
| R-A5 | WARN | `## Docs` is N/A, but the diff touches `*.arb` or `server/migrations/**`. | "Copy and migration changes are usually behaviour — double-check the N/A." |
| R-A6 | WARN | A behaviour path is touched, a `features/*.md` doc is modified, but `## Docs` is N/A. | "You changed a canonical doc — list it under `## Docs` instead of N/A." |

**Exempt authors:** `dependabot[bot]`, `renovate[bot]`, `github-actions[bot]`.
**Exempt label:** `docs-gate-exempt`, applied by a human only. The skill and the steward/babysit files state that agents never apply it.
**Triggers:** `opened`, `synchronize`, `reopened` and `edited`.
**Local parity:** `node scripts/check_docs_canonical.js --pr-body --body-file <file> --base origin/main`. The skill tells agents to run this before creating the PR when the diff touches behaviour paths.

### 4.2 Gate B — change doc lifecycle (`--changes`)

Scope: `docs/domains/*/changes/**/*.md`.

| Rule | Severity | Scope | Condition |
|---|---|---|---|
| R-B1 | BLOCK | Added or modified in the diff | `status` is not `proposed` or `in-delivery`. |
| R-B2 | BLOCK | Added or modified | `folds_into` is missing, or doesn't resolve to a `features/*.md` file at HEAD or added in the diff. |
| R-B3 | BLOCK | Added or modified | `in-delivery` without `plan`. `status_since` is missing or invalid. |
| R-B4 | BLOCK | Added | The filename matches `*-decisions.md`. |
| R-B5 | WARN (PR) / issue (weekly) | Non-baseline | `proposed` with `status_since` more than 30 days old. |
| R-B6 | WARN (PR) / issue (weekly) | Non-baseline | `in-delivery` with `status_since` more than 90 days old **and** the `plan` is complete or closed (snapshot `autonomy ∈ {completed, revoked, halted}`, or issue closed). A doc whose plan is still active is never reported. |
| R-B7 | WARN | Modified | `status_since` changed while `status` did not. "Explain the re-dating under `## Docs`." |

Everything under `docs/domains/*/changes/archive/**` is baseline-only: it can't be added to, is never listed as stale, and leaves the baseline only by deletion. Baseline `changes/` entries are excluded from R-B5 and R-B6 on **every** run, weekly included. Their count shows up in the baseline report (§6) and nowhere else.

### 4.3 Gate C — canonical shape (`--shape`)

Scope: `features/*.md` that are **not** in the baseline.

| Rule | Severity | Condition |
|---|---|---|
| R-C1 | BLOCK | One of the three required H2 headings is missing. |
| R-C2 | BLOCK | A required section has no table with the exact header. A new capability with nothing to list yet uses one placeholder row with `—` in **every column of that table** (3 cells for Requirements and AC, 6 for the Decision log). |
| R-C3 | BLOCK | A requirement ID doesn't match `^<PREFIX>-R-\d{3}$`, or is duplicated within the doc. |
| R-C4 | BLOCK | A requirement or decision `Status` is outside the closed sets in §3.3. |
| R-C5 | BLOCK | An AC `Requirement` cell cites an ID that isn't in this doc's Requirements table. |
| R-C6 | BLOCK | Delivery noise (§4.3.1) in a non-baseline doc. |
| R-C6a | WARN | Delivery noise (§4.3.1) in a **baseline** doc **modified** in the diff. The whole file is scanned; scoping to touched hunks can come later. |
| R-C7 | BLOCK | A decision ID matches neither `^<PREFIX>-D-\d{3}$` nor a legacy pattern (`^D-[A-Z]+-\d{3}$`, `^[A-Z]+-D\d+$`). |

**Baseline docs modified in the PR:** only R-C6a runs (a WARN, to encourage clean-up during sync). All other Gate C rules are skipped.

**Policy-doc exception:** `docs/domains/documentation/**` and `docs/agent-efficiency/**` are out of scope for Gate C. They have no `features/` folder, and the exception in `standards.md` covers them.

#### 4.3.1 Delivery-noise detector

The detector only looks at content **outside** the Requirements and Decision log tables. It flags:
1. **Phase tables:** a table row with one cell matching `^(Phase\s+)?[A-Z]{1,6}-?\d{1,2}[a-z]?$` **and** another cell matching `^(Shipped|Merged|Done|Completed?|Landed|In progress|Pending)$` (case-insensitive). Two things don't count: rows inside the AC table, and cells that match an ID pattern from §3.3.
2. **Banned H2/H3 headings:** `Phasing`, `Delivery status`, `Delivery plan`, `Mockup corrections`, `Change history`, `Changelog`, `Sprint …`.
3. **Amendment banners:** `/\bamended\s+\d{4}-\d{2}-\d{2}\b/i`, or a line starting `**Delivery status:**`. Text inside Decision log cells is never scanned.

There is no inline override. A false positive is fixed by adjusting the detector, with a fixture, in a governance PR.

**Required fixtures:**
- `AW-10` used as an ordinary ID in prose, not flagged;
- `CSM-7 | Shipped`, flagged;
- `X-R-001 | … | In delivery`, not flagged;
- a decision rationale containing "amended 2026-09-29", not flagged.

### 4.4 Gate D — ID stability (`--ids`)

Scope: any `features/*.md` modified in the diff, **including baseline docs** (as soon as they contain stable-format IDs). BASE and HEAD are compared, following git renames.

| Rule | Severity | Condition |
|---|---|---|
| R-D1 | BLOCK | A requirement ID present at BASE is missing at HEAD. "Set it to `Retired`; never delete or reuse a requirement ID." |
| R-D2 | BLOCK | A decision row present at BASE is missing at HEAD, or its `ID`, `Decision`, `Rationale` or `Date` changed. Only `Status` (→ `Superseded by …`) and `PR` (`—` → `#n`) may change. |
| R-D3 | BLOCK | The diff introduces an ID that is already defined in another `features/*.md` file. Latent duplicates already on `main` are listed by the weekly job (§6), not in PRs. |
| R-D4 | — | Renames: IDs are compared across `git diff -M`, so moving a doc during consolidation doesn't trip R-D1. |

Rows that consolidate moves in from a deleted `*-decisions.md` are new rows in the destination doc, so R-D2 allows them.

### 4.5 Gate E — acceptance-criteria trace (`--trace`)

A row is "changed" if its normalised `Given / When / Then` text plus `Requirement` key doesn't exist at BASE.

| Rule | Severity | Scope | Condition |
|---|---|---|---|
| R-T1 | BLOCK | Added or changed AC rows | `Coverage` is not in a normative form (§3.3). |
| R-T2 | BLOCK | Added or changed AC rows | `Coverage` is `TBD — consolidate`. |
| R-T3 | BLOCK | Added or changed AC rows | The `bdd:` file, scenario title or tag doesn't resolve; or the `test:` path or exact test name doesn't resolve. |
| R-T4 | issue (weekly) | All rows | `none — #n` where issue `#n` is closed. |
| R-T5 | REPORT | Repo-wide | The per-domain report (§5). |

## 5. Per-domain trace report (shown alongside the BDD gate)

| Metric | Definition |
|---|---|
| `ac_total` | AC rows |
| `ac_traced_pct` | Rows whose `bdd:` or `test:` resolves, divided by `ac_total` |
| `ac_untraced` | Counts of `none — #n`, `TBD — consolidate` and legacy prose |
| `req_live` | Requirements with status `Live` |
| `req_covered_pct` | `Live` requirements cited by at least one traced AC row, divided by `req_live` |
| `canonical_ratio` | Non-baseline feature docs divided by all feature docs, which tracks migration |

- The job prints this as a Markdown table in `$GITHUB_STEP_SUMMARY`, right after `node e2e/scripts/check_bdd_coverage.js --report-only`. It also produces `--json` output for `quality-kpis.yml`.
- **Report-only.** There is no percentage ratchet. Per-row blocking is handled by R-T1 to R-T3. A per-domain ratchet can be proposed once that domain's `canonical_ratio` reaches 1.0.

## 6. Weekly job (in `quality-kpis.yml`)

Add one job to the existing weekly workflow on `main`. If its schedule or permissions don't fit, it becomes a separate `docs-hygiene.yml`.

1. Run `--changes --all` for R-B5 and R-B6 (non-baseline only), `--ids --report-duplicates` for latent duplicate requirement/decision IDs across `features/*.md` (R-D3, repo-wide), and `--trace --closed-issues` for R-T4.
2. Run `--baseline-report` to count the remaining legacy entries per domain.
3. Create or update **one** issue, found by a marker comment, labelled `tech-debt` and `docs-hygiene`. It has sections for expired proposals, stale in-delivery docs, closed-issue AC rows, duplicate IDs and the legacy count. When everything is empty, the job closes the issue.
4. The job never pushes to `main`.

## 7. Legacy baseline (`scripts/docs-legacy-baseline.json`)

```json
{
  "_comment": "Grandfathered docs. Shrink-only. Remove an entry when /canonical-docs consolidate migrates it.",
  "features": ["…"],
  "changes":  ["…"]
}
```

| Rule | Severity | Condition |
|---|---|---|
| R-L1 | BLOCK | The PR adds an entry (compared with the BASE version of the file). |
| R-L2 | BLOCK | An entry points to a path that no longer exists. "Remove the stale entry." |
| R-L3 | — | `features` entries skip Gate C, except R-C6a (WARN when modified). Gates D and E still apply. **Consolidate exit:** the first PR that removes an entry from the baseline must pass full Gate C, including the BLOCK on R-C6. This is intended. |
| R-L4 | — | `changes` entries skip Gate B **while unmodified**. Once modified, R-B1 to R-B3 apply. |

**Initial content.** The delivery PR generates the file from the current tree at its branch point: every `features/*.md` and every `changes/**/*.md`, including `archive/`. Two cases are left out:
- `docs/domains/documentation/standards.md` is out of scope anyway;
- any `features/*.md` doc that already passes Gate C is left out, so it is protected from day one. For example, a doc created under #1703 conventions.

The PR description records the counts per domain.

## 8. `related_prs`

This is advisory only: R-P1 is a **WARN** when a modified canonical doc's `related_prs` doesn't include the PR number. It is never blocking, because:
- the number isn't known before the first push;
- blocking would force pushes made only to record it, which the Claude rule forbids.

`standards.md` rule 8 is reworded to say this field is a convenience and `git log --follow` is the authoritative history.

## 9. PR template

Keep the merged `## Docs` section, and add a comment explaining what CI checks:

```markdown
## Docs

<!-- CI reads this section (not the checkbox): list canonical doc path(s) updated,
     change docs folded/deleted, IDs added — or `N/A — <reason>`. -->

- [ ] Canonical doc `docs/domains/…` updated (or `N/A — <reason>`: no behaviour change)
```

## 10. Wiring

| Item | Change |
|---|---|
| `scripts/check_docs_canonical.js` + `scripts/lib/docs-canonical/*` | New. Modes: `--pr-body [--body-file] [--base]`, `--changes [--all]`, `--shape`, `--ids`, `--trace`, `--report [--json]`, `--baseline-report`. The default, `--changes --shape --ids --trace`, runs on the diff against `--base` (default `origin/main`). `js-yaml` is resolved the same way as in `check_doc_placement.js`. |
| `scripts/check_docs_canonical.test.js` | Co-located tests, following the conventions of `check_file_size.test.js`. Fixtures go in `scripts/test/fixtures/docs-canonical/`. One test per rule ID, named `R-XX …`. |
| `.github/workflows/docs-gate.yml` | New, triggered on `pull_request` (all paths; types incl. `edited`) with `fetch-depth: 0`. Job **"Docs declaration"** runs `--pr-body`, with no `npm ci`, and must finish in under 1 minute. Job **"Docs canonical"** runs `npm ci` in `server`, then the default mode, then `--report` after the BDD report. Both honour `DOCS_GATE_MODE`. |
| `.github/workflows/docs-validation.yml` | Add the new script, `lib/docs-canonical/**` and the baseline file to `paths`. |
| `.github/workflows/quality-kpis.yml` | Add the weekly job (§6) and `--report --json` collection. |
| `scripts/validate_docs.sh` | Call the default mode against `origin/main` when available, otherwise skip with a notice. |
| `scripts/pre-push-changed.sh` | Run `validate_docs.sh` when the diff touches `docs/**`. |
| `standards.md` | Apply the §0 alignment edits. Rewrite Enforcement as a one-line list of the rule groups (A–E, L), with a pointer to this spec's successor section. |
| `feature-template.md` | Update the AC example to `bdd: ….feature#…` and add a `Retired` note. |
| `.cursor/skills/canonical-docs/SKILL.md` | Step 1 uses `## Docs` / `N/A — …` and step 8 cross-references it. §3 lists the coverage forms and `Retired`. Step 7 (Validate) adds `node scripts/check_docs_canonical.js` and the local `--pr-body --body-file` run. Troubleshooting maps rule IDs to fixes. |
| `.claude/skills/canonical-docs` and `steward` | Pointer-only: "run `check_docs_canonical.js` before pushing", and agents never apply `docs-gate-exempt`. |
| Branch protection | **A human operator step.** Mark "Docs declaration" and "Docs canonical" as required on `main` when PR 2 lands. |

## 11. Rollout

| Step | Content |
|---|---|
| **PR 1** | Script, lib, tests, baseline, workflow (`DOCS_GATE_MODE=warn`), weekly job, `validate_docs.sh` and `pre-push-changed.sh` wiring, and the §0 policy alignment. One outcome: "documentation gates run and report on every PR". |
| **One week** | Review job summaries for false positives. Fix them in small governance PRs, each with a fixture. |
| **PR 2** | Only: set `DOCS_GATE_MODE=block`, and the operator marks both checks as required on `main`. Nothing else ships in PR 2. |

## 12. Acceptance criteria

| Given / When / Then | Requirement | Coverage |
|---|---|---|
| Given a PR changing `server/routes/x.js` with no `## Docs` H2, when the gate runs, then R-A1 fails with the fix message. | R-A1 | test: scripts/check_docs_canonical.test.js#R-A1 missing Docs section |
| Given `## Docs` holds `N/A — refactor, no contract change`, then it passes. Given `N/A — n/a`, then R-A2 fails. | R-A2 | test: …#R-A2 reason length |
| Given `## Docs` lists two feature docs and only one is modified, then R-A3 fails, naming the other. | R-A3 | test: …#R-A3 multi-doc |
| Given the PR body is edited to add `## Docs`, then the gate re-runs and passes. | R-A1 | test: workflow `types` includes `edited` (actionlint plus a fixture on the parsed workflow) |
| Given a change-only PR touching `flutter_app/test/**` only, then Gate A doesn't require `## Docs`. | R-A1 | test: …#R-A1 test-only exempt |
| Given a new `changes/x.md` with `status: completed`, then R-B1 fails. Given an unmodified baseline change doc with `status: frozen`, then nothing fails. | R-B1, R-L4 | test: …#R-B1, #R-L4 |
| Given a new `changes/foo-decisions.md`, then R-B4 fails. | R-B4 | test: …#R-B4 |
| Given a non-baseline proposal 45 days past `status_since`, then the PR gets a warning and the weekly report lists it. Given a baseline `archive/` doc, then it is listed nowhere. | R-B5 | test: …#R-B5 injected clock |
| Given a deleted change doc whose `folds_into` target is unmodified, then R-A4 fails. | R-A4 | test: …#R-A4 |
| Given a non-baseline doc missing `## Decision log`, then R-C1 fails. Given a baseline doc missing it, then nothing fails. | R-C1, R-L3 | test: …#R-C1 |
| Given a non-baseline doc with `\| CSM-7 \| Shipped \|`, then R-C6 fails. Given the same row in a modified baseline doc, then it warns. Given `\| X-R-001 \| … \| In delivery \|`, then nothing is flagged. | R-C6 | test: …#R-C6 fixtures |
| Given `feature_id: people_care_team` and requirement `CARE-TEAM-R-001`, then R-C3 fails, expecting `PEOPLE-CARE-TEAM`. | R-C3 | test: …#R-C3 prefix |
| Given a decision status of `Agreed` in a non-baseline doc, then R-C4 fails with a hint to use `Live`. | R-C4 | test: …#R-C4 decision status |
| Given a requirement row deleted at HEAD, then R-D1 fails. Given it set to `Retired`, then it passes. | R-D1 | test: …#R-D1 |
| Given a decision whose `Rationale` was edited, then R-D2 fails. Given only `Status` changed to `Superseded by X-D-004`, then it passes. | R-D2 | test: …#R-D2 |
| Given a doc renamed with its IDs preserved, then R-D1 doesn't fire. | R-D4 | test: …#R-D4 rename |
| Given a new AC row with `bdd: away_care_planning.feature#Nonexistent`, then R-T3 fails. Given the exact title with curly apostrophes normalised, then it passes. Given `@tag` on the scenario, then it passes. | R-T3 | test: …#R-T3 title/tag |
| Given `test: server/test/x.test.js#adds item` where only `adds item twice` exists, then R-T3 fails (no substring match). | R-T3 | test: …#R-T3 exact name |
| Given a touched AC row still using legacy prose coverage, then R-T1 fails with the normative form in the message. Given an untouched one, then nothing fails. | R-T1 | test: …#R-T1 legacy tolerance |
| Given a new AC row with `TBD — consolidate`, then R-T2 fails. | R-T2 | test: …#R-T2 |
| Given the repo at HEAD, when `--report` runs, then the per-domain table follows the BDD report in the summary and `--json` validates. | R-T5 | test: …#report |
| Given a PR adding a baseline entry, then R-L1 fails. Given an entry for a deleted file, then R-L2 fails. | R-L1, R-L2 | test: …#R-L1, #R-L2 |
| Given `DOCS_GATE_MODE=warn`, then every BLOCK becomes a warning and the exit code is 0. | Mode | test: …#mode |
| Given an unrelated PR on a repo with 90 legacy change docs and stale proposals, then the PR never fails because of them. | P1 | test: …#diff-scope |

## 13. Verification

- The script tests (one per rule ID).
- `node scripts/check_docs_canonical.js --report` on `main`: it runs cleanly, and the baseline counts match the PR description.
- `bash scripts/validate_docs.sh --strict` · `node scripts/check_file_size.js` · `./scripts/pre-push-changed.sh` · actionlint.
- A scratch PR touching a route without `## Docs` shows R-A1 as a warning in warn mode. Close it afterwards.

## 14. Decisions (resolved in review round 1)

| # | Question | Resolution |
|---|---|---|
| 1 | Behaviour path scope | All of `flutter_app/lib/**` (minus generated files), plus `server/bin/**`. Test paths are excluded. |
| 2 | `Retired` status | Accepted. Added to `standards.md`, the skill and the template in the delivery PR. |
| 3 | R-B6 threshold | 90 days, and only when the linked plan is complete or closed. Revisit at 60 days if the weekly issue gets noisy. |
| 4 | Weekly job placement | `quality-kpis.yml`. It moves to a separate workflow only if its schedule or permissions don't fit. |
| 5 | R-C6 on touched legacy docs | WARN on modified baseline docs; BLOCK on non-baseline. |
| 6 | Decision-log status set | `Live` and `Superseded by <ID>`. Legacy `Agreed` maps to `Live` on consolidate. |
| 7 | Header names and order | The merged template (`Rule`; Given/When/Then first) is normative. No renames. |
| 8 | Coverage format | `bdd:` (title or `@tag`), `test:` (path or exact name), `none — #n`. Legacy prose is tolerated on untouched rows only. |
| 9 | `related_bdd` / `related_prs` | Both are advisory (WARN). |

## Still open

(none)
