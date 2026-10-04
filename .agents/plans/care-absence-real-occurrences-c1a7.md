# Child E — real occurrences for absences (`care-absence-real-occurrences-c1a7`)

Parent roadmap: `.agents/plans/care-next-occurrence-c1a7.md` §10 (landing 5b), child E §784–793.

**Integration branch:** `claude/eager-edison-mf34j6`  
**Final landing:** integration → `main` PR with `/babysit-uat` when E+F complete.

## Goal

Absences use stored open occurrences (D-ACP-011): projection, away UI, and E2E match the occurrence engine from A+B/C+D.

## Phases

| id | Scope | exit_checklist |
|----|--------|----------------|
| E1 | `expandItemForWindow` | `default` |
| E2 | Projection / estimate / presentation on E1; remove null-head dead branches | `single-backend-route` |
| E3 | `move_after` → Postpone; Review date; planned + looked-after-by | `single-backend-route` |
| E4 | `buildAbsenceCareView` read model | `single-backend-route` |
| E5 | Flutter away rows carry occurrence id; drop ensure-open usage | `flutter-screen-split` |
| E6 | Corpus + BDD/Playwright (§11.3 E rows) | `bdd-journey` |

## Runtime state

```yaml
autonomy: active
current_phase: E1
next_action: implement expandItemForWindow; PR to integration; babysit+
```
