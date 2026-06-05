---
name: Tool-output token scrambling
description: grep/bash observations sometimes scramble specific source tokens in file CONTENT; the read tool shows truth.
---

Observed: ripgrep/bash command OUTPUT can scramble certain source tokens in file *content* lines
(seen: `weight` → `ln`, so `fontWeight`→`fontln`, `weight_entries`→`ln_entries`, `/api/weight-entries`→`/api/ln-entries`).

**Key facts:**
- It is a DISPLAY artifact only. The actual bytes on disk are unchanged (real token = `weight`).
- The `read` tool renders content CORRECTLY (unscrambled) — trust it over grep/bash for exact strings.
- File PATHS / filenames in tool output are NOT scrambled — only content lines are.
- `edit`/`sed`/`psql` operate on the REAL content, so type the real token (`weight`, not `ln`) and matches work.

**Why it matters:** copying an `old_string` for `edit` from scrambled grep output will fail to match.
**How to apply:** when grep output looks nonsensical (framework identifiers mangled), re-read the file
with the `read` tool to get the true content before editing; don't trust grep's rendering of content.
