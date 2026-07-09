---
name: split-flutter-screen
description: Split an oversized Flutter screen into widgets and controllers under 500 lines. Use when a screen exceeds 300 lines, CI file-size gate fails, or the user asks to extract/refactor a presentation screen.
paths:
  - flutter_app/lib/features/**/presentation/**
  - flutter_app/test/features/**
---

# Split Flutter screen

## When to use

- Hand-written screen file approaching or over **500 lines** (CI blocks new files >500).
- Private widget class **>80 lines** inside a screen file.
- User asks to modularize, extract widgets, or reduce screen complexity.

## Read first

- `docs/architecture/modularity.md` (Flutter section)
- `docs/architecture/index.md` — feature path for mirrored tests

## Steps

1. **Inventory** the screen: form state, async loads, dialogs, tabs, list sections.
2. **Extract controller** (if missing): validation, submit, orchestration → `presentation/controllers/`.
3. **Extract widgets** — one primary widget per file under `presentation/widgets/<screen_name>/`:
   - Sections (header, form fields, lists, dialogs) as separate files.
   - No private widget classes >80 lines left in the screen file.
4. **Thin the screen** to layout composition only (target **<300 lines**).
5. **Mirror tests** in `test/features/<feature>/`:
   - Widget test per extracted widget with meaningful behaviour.
   - Keep existing screen tests green.
6. **Verify:**
   ```bash
   node scripts/check_file_size.js
   cd flutter_app && flutter analyze --no-fatal-warnings --no-fatal-infos
   cd flutter_app && flutter test test/features/<feature>/ --concurrency=1
   ```
7. Log completed split in `docs/refactoring-log.md` if part of a sprint.

## Do not

- Change business logic during a pure split (behaviour-preserving only).
- Leave extracted widgets untested when they contain interaction logic.
- Create files >500 lines.

## Localization

If the screen uses enum `.label` or hardcoded strings, see `.agents/memory/localization-enum-labels.md`.
