---
title: Feature layer cut list (batch I2)
owner: Engineering
audience: agent
status: active
last_updated: 2026-10-05
tags: [architecture, active-codebase, generated]
---

# Feature layer cut list

Base commit: `0577d1d6` (`main`, 2026-10-05). Layer order: [ADR 0002](../../architecture/decisions/0002-feature-layering.md).

**Scope:** every cross-feature import edge that violates ADR 0002 layer rules (`layer(importer) < layer(imported)` or same-tier cross-import). Edges that respect layers but participate in the ten-feature SCC are handled in **phase 3** (not duplicated here).

Directive counts from `scripts/feature-import-baseline.json` at base; file paths are representative import sites (barrel `package:pet_profile_app/features/<name>/<name>.dart`).

## Phase 2 — `pet_profile` composition (D21)

| Edge | Directives | Remedy | Example files |
|------|------------|--------|----------------|
| `pet_profile→health_tracking` | 30 | Move screen/section widgets to `experience/.../pet_profile/`; pass data via constructors/providers owned by experience or `pet_profile` domain types only | `pet_manage_events_screen.dart`, `pet_health_issues_screen.dart`, `pet_list_screen.dart`, `download_report_controller.dart`, `pet_care_section.dart`, `all_care_list.dart`, … |
| `pet_profile→pet_care` | 12 | Move care sections and completeness prompts to experience composition | `pet_profile_health_history_section.dart`, `pet_profile_weight_insight_section.dart`, `pet_care_section.dart`, … |
| `pet_profile→sharing` | 8 | Move org-pets and report-sharing UI to experience | `organization_pets_section.dart`, `download_report_controller.dart`, `pet_care_dashboard_helpers.dart` |
| `pet_profile→weight_tracking` | 7 | Move weight context UI to experience | `pet_detail_profile_card.dart`, `download_report_controller.dart` |
| `pet_profile→notifications` | 4 | Move notification-dependent list/report flows to experience | `pet_list_screen.dart`, `download_report_controller.dart` |
| `pet_profile→vet` | 3 | Move vet contact wiring to experience | (via people/vet providers on profile surfaces — phase 2 relocation) |
| `pet_profile→care_intelligence` | 2 | Move insight/completeness widgets to experience | `pet_detail_scroll_body.dart`, `pet_form_weight_context_section.dart` |
| `pet_profile→people` | 2 | Move vet-contact provider usage to experience | `pet_vet_contacts_provider.dart` |
| `pet_profile→pet_tags` | 1 | Move tag chip section to experience | `pet_detail_scroll_body.dart` |

**Phase 2 exit:** zero `pet_profile→{health_tracking,weight_tracking,pet_care,sharing,vet,notifications,care_intelligence}` edges.

## Phase 3 — Remaining layer violations

| Edge | Directives | Remedy |
|------|------------|--------|
| `care_item→health_tracking` | 9 | Invert: expose agenda hooks from `health_tracking` entrypoint or move orchestration to `pet_care` / `experience` |
| `care_item→pet_care` | 7 | Move grouping reads behind `pet_care` port; `care_item` stays leaf |
| `care_item→pet_profile` | 4 | Remove; agenda lines composed in `experience` |
| `care_intelligence→pet_care` | 4 | Pull recommendations via callback/port from `pet_care` into CIM coordinator |
| `health_tracking→pet_care` | 5 | Split shared types to `core` or invert schedule reads through `pet_care` public API |
| `pet_care→care_intelligence` | 3 | Invert dependency: CIM consumes `pet_care` events via port (no `pet_care→care_intelligence`) |
| `care_taxonomy→pet_profile` | 3 | Move taxonomy-driven profile labels to experience or `pet_profile` domain mapper |
| `care_taxonomy→health_tracking` | 1 | Pass taxonomy ids as primitives; no feature import |
| `care_item→people` | 1 | Compose people picker in experience |
| `health_tracking→people` | 1 | Vet/people picker at experience layer |
| `people→sharing` | 1 | Collapse through `experience` share flows or shared port in `core` |
| `people→vet` | 1 | Route-level composition only |
| `auth→about` | 1 | Allow via L7 leaf rule or move link widget to `about` importing `auth` only (invert) |

## Phase 3 — SCC edges that already respect layers

These edges are **not** layer violations but must still be removed for R5 (`SCC = 0`):

- Examples: `health_tracking→care_taxonomy`, `health_tracking→care_item`, `notifications→pet_profile`, `people→pet_profile`, `vet→pet_profile`, `sharing→pet_profile`, `experience→*` (composition — allowed), and other cycle chords listed in the baseline.

Track removal against `node scripts/check_feature_imports.js --summary` until no multi-feature SCC remains.
