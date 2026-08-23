---
title: Domain-first documentation audit (wave 3)
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
tags: [audit,documentation,domain-first]
---

# Domain-first documentation audit

Full inventory of repository `.md` files (2026-08-22 wave 3). **Outcome:** waves 1–2 relocated delivery plans; wave 3 confirms **no further physical `git mv` required** for misplaced domain docs. Remaining work is **debt row migration** and **index cleanup**.

## Summary

| Category | Count | Decision |
|----------|-------|----------|
| Domain canonical (`docs/domains/`) | 91 | STAY |
| Legacy redirect stubs | 23 | STAY (preserve inbound links) |
| Experience program (cross-cutting) | 8 | STAY |
| Agent efficiency / tooling | 70+ | STAY (never move `.agents/plans/`) |
| E2E / CI / platform index | 22 | STAY (cross-cutting; many inbound links) |
| Design system | 7 | STAY (`skin-change-guide` is whole-app re-skin, not org-only) |
| Debt indexes | 3 | MIGRATE rows → domain `changes/deferred.md` |
| Platform index (`docs/README.md`, etc.) | 13 | UPDATE stale legacy tables |

**Total tracked:** ~330 markdown files (excludes `node_modules`).

## Wave 3 actions

1. Migrate domain-scoped debt rows from `technical-debt.md` / `refactoring-debt.md` into `docs/domains/*/changes/deferred.md`.
2. Trim legacy debt files to pointers + changelog (dedupe with `docs/debt/deferred.md`).
3. Fix `docs/README.md` fostering-platform table (only redirect README remains).
4. Fix organisation dashboard brief links to domain `changes/` paths.

## Files explicitly not moved (reviewed)

| Path | Reason to keep |
|------|----------------|
| `docs/design/skin-change-guide.md` | Whole-app palette swap (`app_color_tokens.dart`); org teal is one consumer |
| `docs/e2e/navigation-contract.md` | Cross-cutting Playwright contract; 15+ inbound links |
| `docs/pipelines/e2e-ci-canary-plan.md` | Cross-cutting CI initiative; linked from `ci-cd-gates.md` |
| `docs/experience-program/*` (non-stub) | Program-level decisions, roadmap, phases 0–1, reconciliation |
| `.agents/plans/*`, `.agents/memory/*` | Policy: link-out only, never physical move |

## Full inventory by category

## agent-efficiency (12)
- docs/agent-efficiency/plans/agent-efficiency-plan.md
- docs/agent-efficiency/atomic-pr-policy.md
- docs/agent-efficiency/autonomous-pr-policy.md
- docs/agent-efficiency/execute-plan-runtime.md
- docs/agent-efficiency/execute-plan-schema.md
- docs/agent-efficiency/github-labels.md
- docs/agent-efficiency/phase-exit-checklists.md
- docs/agent-efficiency/plan-template.md
- docs/agent-efficiency/pr-review-cost-efficiency.md
- docs/agent-efficiency/prompt-templates.md
- docs/agent-efficiency/uat-coordinator-bootstrap.md
- docs/agent-efficiency/uat-coordinator-plan.md

## agents-other (25)
- .agents/issues/ux-overhaul-recovery.md
- .agents/memory/MEMORY.md
- .agents/memory/auth-token-refresh.md
- .agents/memory/body-supplied-org-id-validation.md
- .agents/memory/canonical-product-name.md
- .agents/memory/error-leak-redaction-patterns.md
- .agents/memory/execute-plan-autonomy.md
- .agents/memory/flutter-inksparkle-test-harness.md
- .agents/memory/flutter-preview-lockfile-resolver.md
- .agents/memory/flutter-pubcache-matrix4.md
- .agents/memory/flutter-web-password-managers.md
- .agents/memory/github-api-publish-fallback.md
- .agents/memory/guardian-mobile-completion.md
- .agents/memory/health-entry-completion.md
- .agents/memory/jwt-secret-dev-fallback.md
- .agents/memory/local-first-sync.md
- .agents/memory/localization-enum-labels.md
- .agents/memory/mockup-sandbox-registration.md
- .agents/memory/public-access-gate.md
- .agents/memory/replit-agent-operating-policy.md
- .agents/memory/replit-chromium-nix-runtime.md
- .agents/memory/replit-flutter-preview-compatibility.md
- .agents/memory/tool-output-token-scrambling.md
- .agents/memory/uat-live-e2e-triage.md
- .agents/memory/unrelated-history-migration.md

## agents-plans (37)
- .agents/plans/README.md
- .agents/plans/_example.md
- .agents/plans/agent-efficiency-automation-e1a4.md
- .agents/plans/ci-fix-plan.md
- .agents/plans/ci-speedup.md
- .agents/plans/ci-test-depth-abc9.md
- .agents/plans/ci-uat-promote-restore-5641.md
- .agents/plans/db-schema-bootstrap-345.md
- .agents/plans/docs-domain-audit-63ad.md
- .agents/plans/docs-domain-reorg-63ad.md
- .agents/plans/docs-domain-sweep-63ad.md
- .agents/plans/e2e-ci-canary.md
- .agents/plans/e2e-flutter344-uat-unblock-5641.md
- .agents/plans/experience-program-36bd.md
- .agents/plans/fostering-platform-foundation-e877.md
- .agents/plans/fostering-platform-j1-phase2-e877.md
- .agents/plans/fostering-platform-j1-phase3-e877.md
- .agents/plans/fostering-platform-j1-phase4-e877.md
- .agents/plans/fostering-platform-wave-c-e877.md
- .agents/plans/guardian-semantics-preuat-2600.md
- .agents/plans/guardian-ui-rework-5dd0.md
- .agents/plans/guardian-ui-wave2-5dd0.md
- .agents/plans/org-mode-navigation-acf1.md
- .agents/plans/org-ux-polish-badd.md
- .agents/plans/organisation-ux-v3-badd.md
- .agents/plans/organisation-v2-abc9.md
- .agents/plans/organisation-v4-people-perms.md
- .agents/plans/pet-timeline-segments-a03d.md
- .agents/plans/pet-timeline-view-a03d.md
- .agents/plans/public-access-gate-a35f.md
- .agents/plans/uat-agent-babysit-5641.md
- .agents/plans/uat-coordinator-launch-fix-7808.md
- .agents/plans/uat-pre-e2e-pipeline-5641.md
- .agents/plans/uat-queue-pr-fallback-2936.md
- .agents/plans/ui-navigation-v2-14ee.md
- .agents/plans/ui-theme-rework-4bed.md
- .agents/plans/ux-overhaul-plan.md

## architecture (2)
- docs/architecture/index.md
- docs/architecture/modularity.md

## archived (4)
- docs/archived/README.md
- docs/archived/experience-split-plan.md
- docs/archived/navigation-v2.md
- docs/archived/quality-review-2026-07-08.md

## code-adjacent (19)
- flutter_app/assets/legal/en/dpa.md
- flutter_app/assets/legal/en/legal-notice.md
- flutter_app/assets/legal/en/privacy-notice.md
- flutter_app/assets/legal/en/terms-of-use.md
- flutter_app/assets/legal/fr/conditions-dutilisation.md
- flutter_app/assets/legal/fr/dpa.md
- flutter_app/assets/legal/fr/mentions-legales.md
- flutter_app/assets/legal/fr/politique-de-confidentialite.md
- flutter_app/lib/features/health_tracking/presentation/widgets/health_dashboard/README.md
- flutter_app/lib/features/health_tracking/presentation/widgets/health_entry_form/README.md
- flutter_app/lib/features/organization/data/datasources/organization_remote/README.md
- flutter_app/lib/features/pet_profile/presentation/widgets/pet_list/README.md
- flutter_app/lib/features/pet_profile/presentation/widgets/sharing/README.md
- flutter_app/test/bdd/step_definitions/README.md
- flutter_app/test/bdd/support/README.md
- flutter_app/test/features/organization/presentation/providers/README.md
- server/routes/auth/README.md
- server/routes/organizations/README.md
- server/routes/pets/README.md

## debt-index (3)
- docs/debt/deferred.md
- docs/debt/refactoring-debt.md
- docs/debt/technical-debt.md

## design (7)
- docs/design/agathatrack-redesign-blueprint.md
- docs/design/copy-tone.md
- docs/design/index.md
- docs/design/principles.md
- docs/design/skin-change-guide.md
- docs/design/tokens.md
- docs/design/ui-rework-plan.md

## domain-canonical (91)
- docs/domains/auth/README.md
- docs/domains/auth/changes/deferred.md
- docs/domains/auth/changes/lessons.md
- docs/domains/auth/changes/plans.md
- docs/domains/auth/features/journeys.md
- docs/domains/auth/features/specs.md
- docs/domains/fostering/README.md
- docs/domains/fostering/changes/deferred.md
- docs/domains/fostering/changes/lessons.md
- docs/domains/fostering/changes/org-fostering-strategy.md
- docs/domains/fostering/changes/phase-4-foster-pet-operations.md
- docs/domains/fostering/changes/plans.md
- docs/domains/fostering/changes/roadmap-delivery-plan.md
- docs/domains/fostering/features/foster-placement-lifecycle.md
- docs/domains/fostering/features/g0-contract-pack.md
- docs/domains/fostering/features/j1-foster-onboarding.md
- docs/domains/fostering/features/journeys.md
- docs/domains/fostering/features/migration-appendix.md
- docs/domains/fostering/features/specs.md
- docs/domains/health_tracking/README.md
- docs/domains/health_tracking/changes/deferred.md
- docs/domains/health_tracking/changes/lessons.md
- docs/domains/health_tracking/changes/plans.md
- docs/domains/health_tracking/features/journeys.md
- docs/domains/health_tracking/features/specs.md
- docs/domains/help_about/README.md
- docs/domains/help_about/changes/deferred.md
- docs/domains/help_about/changes/lessons.md
- docs/domains/help_about/changes/plans.md
- docs/domains/help_about/features/journeys.md
- docs/domains/help_about/features/specs.md
- docs/domains/notifications/README.md
- docs/domains/notifications/changes/deferred.md
- docs/domains/notifications/changes/lessons.md
- docs/domains/notifications/changes/plans.md
- docs/domains/notifications/features/journeys.md
- docs/domains/notifications/features/specs.md
- docs/domains/organization/README.md
- docs/domains/organization/changes/deferred.md
- docs/domains/organization/changes/lessons.md
- docs/domains/organization/changes/organisation-people-permissions-v4-delivery-plan.md
- docs/domains/organization/changes/organisation-ux-v3-delivery-plan.md
- docs/domains/organization/changes/organisation-v2-delivery-plan.md
- docs/domains/organization/changes/phase-3-organisation-presentation.md
- docs/domains/organization/changes/phase-3-ui-design-review.md
- docs/domains/organization/changes/phase-5-organisation-customisations.md
- docs/domains/organization/changes/phase-5-ui-design-review.md
- docs/domains/organization/changes/plans.md
- docs/domains/organization/features/journeys.md
- docs/domains/organization/features/org-custody-model.md
- docs/domains/organization/features/org-member-privacy.md
- docs/domains/organization/features/org-roles-and-permissions.md
- docs/domains/organization/features/organisation-dashboard-brief.md
- docs/domains/organization/features/specs.md
- docs/domains/pet_profile/README.md
- docs/domains/pet_profile/changes/deferred.md
- docs/domains/pet_profile/changes/guardian-today-contract.md
- docs/domains/pet_profile/changes/guardian-today-orientation-handoff.md
- docs/domains/pet_profile/changes/guardian-today-presentation-foundation.md
- docs/domains/pet_profile/changes/guardian-ui-wave2-issue-briefs.md
- docs/domains/pet_profile/changes/lessons.md
- docs/domains/pet_profile/changes/phase-2-guardian-journey.md
- docs/domains/pet_profile/changes/plans.md
- docs/domains/pet_profile/features/guardian-dashboard-brief.md
- docs/domains/pet_profile/features/journeys.md
- docs/domains/pet_profile/features/pet-activity-model.md
- docs/domains/pet_profile/features/specs.md
- docs/domains/sharing/README.md
- docs/domains/sharing/changes/deferred.md
- docs/domains/sharing/changes/lessons.md
- docs/domains/sharing/changes/plans.md
- docs/domains/sharing/features/journeys.md
- docs/domains/sharing/features/specs.md
- docs/domains/subscription/README.md
- docs/domains/subscription/changes/deferred.md
- docs/domains/subscription/changes/lessons.md
- docs/domains/subscription/changes/plans.md
- docs/domains/subscription/features/journeys.md
- docs/domains/subscription/features/specs.md
- docs/domains/vet/README.md
- docs/domains/vet/changes/deferred.md
- docs/domains/vet/changes/lessons.md
- docs/domains/vet/changes/plans.md
- docs/domains/vet/features/journeys.md
- docs/domains/vet/features/specs.md
- docs/domains/weight_tracking/README.md
- docs/domains/weight_tracking/changes/deferred.md
- docs/domains/weight_tracking/changes/lessons.md
- docs/domains/weight_tracking/changes/plans.md
- docs/domains/weight_tracking/features/journeys.md
- docs/domains/weight_tracking/features/specs.md

## e2e-ops (9)
- docs/pipelines/e2e-ci-canary-plan.md
- docs/e2e/navigation-contract.md
- docs/e2e/uat-agent-babysit.md
- docs/e2e/uat-demo-data.md
- docs/e2e/uat-demo-personas.md
- docs/e2e/uat-deploy-tiers.md
- docs/e2e/uat-live-operations-runbook.md
- docs/e2e/uat-promote-manual.md
- docs/e2e/uat-waf-queue-lessons.md

## experience-program (8)
- docs/experience-program/briefs/navigation-brief.md
- docs/experience-program/decisions-log.md
- docs/experience-program/phase-0-foundation.md
- docs/experience-program/phase-0-settings-audit.md
- docs/experience-program/phase-1-navigation.md
- docs/experience-program/phase-r-reconciliation.md
- docs/experience-program/program-contract.md
- docs/experience-program/roadmap-delivery-plan.md

## legacy-stub (23)
- docs/architecture/org-custody-model.md
- docs/architecture/org-member-privacy.md
- docs/architecture/pet-activity-model.md
- docs/experience-program/README.md
- docs/experience-program/briefs/guardian-dashboard-brief.md
- docs/experience-program/briefs/guardian-ui-wave2-issue-briefs.md
- docs/experience-program/briefs/organisation-dashboard-brief.md
- docs/experience-program/guardian-today-contract.md
- docs/experience-program/guardian-today-orientation-handoff.md
- docs/experience-program/guardian-today-presentation-foundation.md
- docs/experience-program/organisation-people-permissions-v4-delivery-plan.md
- docs/experience-program/organisation-ux-v3-delivery-plan.md
- docs/experience-program/organisation-v2-delivery-plan.md
- docs/experience-program/phase-2-guardian-journey.md
- docs/experience-program/phase-3-organisation-presentation.md
- docs/experience-program/phase-3-ui-design-review.md
- docs/experience-program/phase-4-foster-pet-operations.md
- docs/experience-program/phase-5-organisation-customisations.md
- docs/experience-program/phase-5-ui-design-review.md
- docs/fostering-platform/README.md
- docs/org-fostering-strategy.md
- docs/sprint-10-flutter-344-execution-plan.md
- docs/sprint-6-execution-plan.md

## ops (1)
- docs/ops/public-access.md

## plans-index (4)
- docs/plans/README.md
- docs/plans/documentation-consolidation-plan.md
- docs/plans/sprint-10-flutter-344-execution-plan.md
- docs/plans/sprint-6-execution-plan.md

## platform-index (13)
- docs/CHANGELOG.md
- docs/README.md
- docs/api-reference.md
- docs/calendar-dates.md
- docs/pipelines/ci-build-artifact-contract.md
- docs/pipelines/ci-cd-baseline.md
- docs/pipelines/ci-cd-gates.md
- docs/pipelines/db-schema-bootstrap-plan.md
- docs/agent-efficiency/github-issue-workflow.md
- docs/ops/observability.md
- docs/pipelines/promotion-contract.md
- docs/debt/refactoring-log.md
- docs/pipelines/uat-backend-node-modules-runbook.md

## quality (2)
- docs/quality/bdd-journey-matrix.md
- docs/quality/scorecard.md

## regulatory (13)
- regulatory/DATA_MAP.md
- regulatory/INTERNAL_GDPR.md
- regulatory/PRIVACY_POLICY.md
- regulatory/TERMS_OF_SERVICE.md
- regulatory/internal/dpia-foster-directory.md
- regulatory/legal/en/dpa.md
- regulatory/legal/en/legal-notice.md
- regulatory/legal/en/privacy-notice.md
- regulatory/legal/en/terms-of-use.md
- regulatory/legal/fr/conditions-dutilisation.md
- regulatory/legal/fr/dpa.md
- regulatory/legal/fr/mentions-legales.md
- regulatory/legal/fr/politique-de-confidentialite.md

## repo-root (6)
- AGENTS.md
- CONTRIBUTING.md
- DEPLOYMENT_CPANEL_NODEJS.md
- DEPLOYMENT_DB.md
- README.md
- replit.md

## scripts (1)
- scripts/BABYSIT_README.md

## tooling (21)
- .cursor/BUGBOT.md
- .cursor/commands/babysit-uat.md
- .cursor/commands/babysit.md
- .cursor/commands/execute-plan.md
- .cursor/commands/review-bugbot.md
- .cursor/skills/add-bdd-playwright-scenario/SKILL.md
- .cursor/skills/babysit-plus/SKILL.md
- .cursor/skills/babysit-uat/SKILL.md
- .cursor/skills/execute-plan/SKILL.md
- .cursor/skills/pre-push-verify/SKILL.md
- .cursor/skills/security-error-audit/SKILL.md
- .cursor/skills/single-backend-route-change/SKILL.md
- .cursor/skills/spawn-sprint-agents/SKILL.md
- .cursor/skills/split-flutter-screen/SKILL.md
- .cursor/skills/ui-check/SKILL.md
- .cursor/skills/ui-design-deep/SKILL.md
- .github/instructions/*.instructions.md
- .github/instructions/pr-workflow.instructions.md
- .github/pull_request_template.md
- e2e/README.md
- e2e/features/README.md


---

*Generated during execute-plan `docs-domain-audit-63ad` phase 1.*
