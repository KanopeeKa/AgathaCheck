---
name: canonical-docs
description: Keep domain feature docs current on every PR (sync) and reconcile legacy sources per capability (consolidate). Policy in docs/domains/documentation/standards.md — run Mode A before opening or updating behaviour PRs.
---

# Canonical docs

**Policy (do not restate here):** `docs/domains/documentation/standards.md`

Two modes. **Mode A (`sync`)** is mandatory on every agent PR when behaviour changes. **Mode B (`consolidate`)** runs only when explicitly requested — one capability per PR.

---

## Mode A — `sync` (every PR)

Run **before** `ManagePullRequest create_pr` / PR update that ships new behaviour. Same order as babysit-plus §Pre-PR (documentation before verification).

### 1. Classify the diff

Add a `## Docs` section to the PR body (CI Gate A reads this heading — not the template checkbox alone). Use `N/A — <reason ≥10 chars>` when no domain feature doc applies.

| Condition | Docs |
|-----------|------|
| Copy, terminology, or l10n change | **Behaviour** |
| User-visible UI flow, state, or rule | **Behaviour** |
| API, wire format, or validation change | **Behaviour** |
| Persisted-data semantics or permissions | **Behaviour** |
| Refactor; identical wire/API and rules | N/A — `refactor, no contract change` |
| Internal helper; same HTTP contract; no rule moved | N/A |
| Migration backfill/reshape only; meaning unchanged | N/A |
| Observability/logging only | N/A unless user-visible or support playbook changes |
| Tests, CI, tooling, or agent workflow only | N/A for **domain** feature docs |
| Edits under `.cursor/`, `docs/agent-efficiency/`, or agent scripts only | N/A for domain docs; update the relevant policy/skill doc in the same PR |

If N/A: add `## Docs` with `N/A — <reason>` (see step 8) and stop.

### 2. Locate canonical doc(s)

Domain `README.md` first, then `docs/architecture/index.md`. Do not broad-search the repo.

If none exists for the capability, create `docs/domains/<domain>/features/<capability>.md` from `docs/domains/documentation/feature-template.md`.

### 3. Update canonical doc (post-merge truth)

- **Requirements:** stable IDs `<PREFIX>-R-###` where prefix = doc `feature_id` uppercased with `_` → `-` (see standards). Status: `Live` | `In delivery` | `Planned`.
- **Acceptance criteria:** Given/When/Then; cite requirement ID and BDD/test.
  - **New or changed in this PR:** test reference or `Coverage: none — issue #…`.
  - **Legacy untouched:** `Coverage: TBD — consolidate` is allowed.
- **Decision log:** append `<PREFIX>-D-###` per decision; supersede old rows with `Superseded by <ID>`.
- Remove delivery noise from sections you touch (phase tables, “amended on …” banners).

Standalone `*-decisions.md` under `features/` or `changes/` is **legacy** — do not create new ones; fold on delivery or via consolidate.

### 4. Fold `changes/` docs

When this PR delivers work documented under `changes/` (including legacy `*-decisions.md` / `*-spec.md` there):

1. Move delivered requirements, ACs, and decisions into the canonical doc.
2. Apply the **deletion guard** (Mode B §4): delete only when the canonical doc **fully** supersedes the source; trim + `status: in-delivery` when scope remains; never delete if an active plan still references the file (`grep -rn <file> .agents/plans docs`).
3. Fix inbound links; update domain README.

### 5. Frontmatter

Set `last_updated`. Append this PR number to `related_prs` (after PR exists if needed).

### 6. Memory files

Only when this PR **changes a product rule documented solely in `.agents/memory/`**, or edits such a file: move the rule into the canonical doc; leave memory as an agent lesson linking to it.

### 7. Validate

```bash
cd server && npm ci   # if js-yaml missing
bash scripts/validate_docs.sh
# Optional local Gate A parity with CI:
DOCS_BASE_SHA="$(git merge-base HEAD origin/main)" DOCS_HEAD_SHA=HEAD \
  node scripts/check_docs_canonical.js --pr-body --body-file /path/to/pr-body.md
```

See **Troubleshooting** below on failures.

### 8. PR body `## Docs`

List: canonical paths updated; change docs folded/deleted/trimmed; requirement/decision IDs added; or `N/A — reason`.

### 9. Product conflicts

Code, tests, and docs disagree on **intent** → do not guess.

- Row under `## Still open` in the canonical doc **with a linked GitHub issue**.
- Escalate per `docs/agent-efficiency/autonomous-pr-policy.md` (`**Needs you:**` on control issue when merge safety is ambiguous).
- Ordinary open questions (not code vs spec conflict) → `## Still open` without an issue.

---

## Mode B — `consolidate <domain>/<capability>`

On demand only. **One capability per PR.**

1. **Inventory:** `features/` and `changes/` in all relevant domains; domain README; `.agents/memory/`; referenced `.agents/plans/`; `docs/design/`, `docs/architecture/`.
2. **Reconcile** each rule against code and BDD/Jest; tag `Live` | `In delivery` | `Planned`. Conflicts → Mode A §9.
3. **Write** one canonical doc (template structure). **Decision log:** keep existing IDs (`D-CSM-019`, …); bare legacy IDs (`D1`…) → prefix (e.g. `NAV-D1`) with old ID noted.
4. **Deletion guard, then delete or trim:**
   - Delete only when fully superseded.
   - Leave `in-delivery` when multi-phase plans or other streams still need the file.
   - Never delete if `grep -rn <file> .agents/plans docs` shows active references.
   - Sweep links; update domain README and `docs/README.md`.
5. **PR body:** source → destination table; conflicts (with issue links); deleted/trimmed files.

---

## Troubleshooting

| Symptom | Action |
|---------|--------|
| `js-yaml is required` | `cd server && npm ci` |
| `check_doc_placement` / manifest errors | Fix path, frontmatter (`domain`, `feature_id`), or token links — **do not** weaken checks in this repo workflow |
| **R-A1** missing `## Docs` | Add `## Docs` with canonical paths or `N/A — reason` |
| **R-A3** path not in diff | List only docs this PR actually changes |
| **R-C6** delivery noise | Remove phase/shipped tables, `## Phasing`, amendment banners from canonical body |
| **R-T2** / **R-T3** coverage | Use `bdd:`, `test:`, or `none — #issue` wire formats (see feature-template) |
| New feature doc fails gates | Ensure file lives under `features/`, valid YAML, `## Decision log`, no hex colours in prose |

Rule IDs: `docs/domains/documentation/standards.md` §Enforcement.

---

## Related

| Skill / doc | When |
|-------------|------|
| `/babysit-plus` | Must-fix if behaviour PR lacks doc sync or `## Docs` |
| `/execute-plan` | Phase `docs_targets`; plan completion checklist |
| `docs/domains/documentation/standards.md` | Policy and ID conventions |
