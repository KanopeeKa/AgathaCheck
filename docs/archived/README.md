---
title: Archived Documentation
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-21
tags: [archived,historical,documentation]
---

# Archived Documentation

> ⚠️ **These documents are kept for historical reference only.**
> They have been superseded by newer documentation or are point-in-time snapshots that are no longer actively maintained.

---

## 📜 **Purpose**

This directory contains documentation that:
- Has been **superseded** by newer, more accurate documentation
- Represents **point-in-time snapshots** (e.g., sprint reviews, historical decisions)
- Is **no longer relevant** to the current codebase or workflows
- Is kept for **historical context** or compliance reasons

**Do not use these documents for active development.** Instead, refer to the current documentation in the parent `docs/` directory.

---

## 📚 **Archived Documents**

### Superseded by navigation domain docs

These documents have been replaced by the [navigation domain](/docs/domains/navigation/README.md) and related domain decision docs.

| Original Path | Archived Path | Replacement | Reason |
|---------------|---------------|--------------|--------|
| `docs/design/navigation-v2.md` | [navigation-v2.md](navigation-v2.md) | [navigation domain](/docs/domains/navigation/README.md) | Navigation redesign superseded |
| `docs/experience-split-plan.md` | [experience-split-plan.md](experience-split-plan.md) | [phase-r-reconciliation.md](/docs/domains/navigation/changes/phase-r-reconciliation.md) | Reconciled into Phase R |

### Point-in-Time Snapshots

These documents capture historical states and are not maintained.

| Original Path | Archived Path | Date | Purpose |
|---------------|---------------|------|---------|
| `docs/quality/review-2026-07-08.md` | [quality-review-2026-07-08.md](quality-review-2026-07-08.md) | 2026-07-08 | Quality review snapshot |

---

## 🔍 **How to Use Archived Documentation**

### Before Using an Archived Document

1. **Check the replacement**: Each entry above links to the current documentation that supersedes it.
2. **Verify the date**: Archived documents may be significantly out of date.
3. **Consult the team**: If you're unsure whether an archived document is still relevant, ask in a GitHub issue.

### Finding Current Documentation

Use the **[master table of contents](../README.md)** to find the current, actively maintained documentation.

---

## 🗑️ **Deprecation Policy**

### When to Archive

Documentation should be archived when:
- It has been **superseded** by a newer document covering the same topic
- It describes **deprecated features** or workflows that are no longer used
- It represents a **point-in-time decision** that is no longer relevant
- It contains **outdated information** that would be misleading to contributors

### When to Delete

Documentation may be **deleted entirely** (rather than archived) when:
- It contains **no historical value**
- It describes **features that never shipped**
- It is a **duplicate** of another document
- It contains **sensitive information** that should not be retained

### Archive Process

1. **Move the file** to `docs/archived/` with its original name
2. **Add a deprecation header** at the top of the file:
   ```markdown
   > ⚠️ **ARCHIVED**: This document has been superseded by [new-document.md](../new-document.md).
   > It is kept for historical reference only. Do not use for active development.
   ```
3. **Update this README.md** to list the archived document
4. **Update all cross-references** to point to the archived location or the replacement
5. **Update the master TOC** ([docs/README.md](../README.md)) to mark it as archived

---

## 📝 **Archived Document Template**

When archiving a document, prepend the following header:

```markdown
> ⚠️ **ARCHIVED**: This document has been superseded by [replacement-document.md](../../replacement-document.md).
> 
> **Original Location**: `docs/original/path.md`
> **Archived Date**: YYYY-MM-DD
> **Reason**: [Brief explanation of why it was archived]
> 
> This document is kept for historical reference only. Do not use for active development.

---

[Original content begins below]
```

---

## 🔗 **Related Documentation**

- [Master Documentation Index](../README.md)
- [Navigation domain](/docs/domains/navigation/README.md) - Supersedes many archived docs
- [Refactoring Log](../refactoring-log.md) - Tracks changes including documentation updates

---

*Last updated: 2026-08-21*
