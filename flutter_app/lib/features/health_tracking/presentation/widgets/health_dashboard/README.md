# Health dashboard widgets

Extracted from `health_dashboard_screen.dart` to keep the screen an orchestrator
under the ~500-line modularity budget.

| Widget / helper | File |
|-----------------|------|
| `HealthDashboardEntryList` | `health_dashboard_entry_list.dart` |
| `HealthDashboardOrgFilter` | `health_dashboard_org_filter.dart` |
| `buildEventsPdfGroups` | `health_dashboard_pdf_groups.dart` |

`HealthDashboardActions` (app-bar sort/export menu) and the shared `GroupMode`
enum live in the sibling `../health_dashboard_actions.dart`.

The screen keeps tab/app-bar wiring, the FAB, and the CSV/PDF export flows; the
per-tab grouped list, org filter chips, and PDF grouping logic live here.
