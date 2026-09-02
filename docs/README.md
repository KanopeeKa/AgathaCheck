---
title: Agatha Track Documentation
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-23
tags: [overview,table-of-contents,documentation]
---

# Agatha Track Documentation

> **Master Table of Contents** - Start here for all project documentation

This directory contains all technical and operational documentation for **Agatha Track** (formerly PetProfileApp). Use this file as your entry point to navigate the documentation structure.

---

## Core Documentation

Foundational documents that describe the project's architecture, setup, and workflows.

| Document | Purpose | Audience |
|----------|---------|----------|
| [/docs/architecture/index.md](/docs/architecture/index.md) | Domain map, tech stack, and code organization | Both |
| [/docs/architecture/api-reference.md](/docs/architecture/api-reference.md) | REST endpoint reference (authoritative) | Both |
| [/docs/architecture/calendar-dates.md](/docs/architecture/calendar-dates.md) | `YYYY-MM-DD` wire format specification | Both |
| [/docs/pipelines/ci-cd-baseline.md](/docs/pipelines/ci-cd-baseline.md) | Pipeline metrics and performance targets | Both |
| [/docs/pipelines/ci-cd-gates.md](/docs/pipelines/ci-cd-gates.md) | Blocking vs advisory gates, UAT/PROD rules | Both |

---

## Product domains (domain-first)

Each product area has a one-screen index under `docs/domains/<domain>/` with journeys, specs, plans, lessons, and deferred work.

| Domain | Index | Focus |
|--------|-------|-------|
| Authentication | [/docs/domains/auth/README.md](/docs/domains/auth/README.md) | Login, signup, profile |
| Pet profiles | [/docs/domains/pet_profile/README.md](/docs/domains/pet_profile/README.md) | Pets, guardian dashboard, timeline |
| Health tracking | [/docs/domains/health_tracking/README.md](/docs/domains/health_tracking/README.md) | Medication, due dates, health issues |
| Weight tracking | [/docs/domains/weight_tracking/README.md](/docs/domains/weight_tracking/README.md) | Weight history and charts |
| Veterinarians | [/docs/domains/vet/README.md](/docs/domains/vet/README.md) | Vet contacts and pet links |
| Sharing | [/docs/domains/sharing/README.md](/docs/domains/sharing/README.md) | Share links and collaborators |
| Notifications | [/docs/domains/notifications/README.md](/docs/domains/notifications/README.md) | In-app notification feed |
| Shelter | [/docs/domains/shelter/README.md](/docs/domains/shelter/README.md) | Shelter identity, permissions, privacy, custody model |
| Fostering | [/docs/domains/fostering/README.md](/docs/domains/fostering/README.md) | Placements, adoption, custody transfers |
| Subscription | [/docs/domains/subscription/README.md](/docs/domains/subscription/README.md) | Premium tiers (billing TBD) |
| Help & about | [/docs/domains/help_about/README.md](/docs/domains/help_about/README.md) | FAQ and about screens |

Cross-cutting open debt: [/docs/debt/debt.md](/docs/debt/debt.md)

---

## Documentation by type (cross-cutting)

Product behaviour → `docs/domains/<domain>/`. Platform, CI, agents, and debt → folders below.

| Folder | Index | Contents |
|--------|-------|----------|
| **Pipelines** | [/docs/pipelines/README.md](/docs/pipelines/README.md) | CI/CD gates, promotion, canary, deploy runbooks |
| **Agent efficiency** | [/docs/agent-efficiency/plans/README.md](/docs/agent-efficiency/plans/README.md) | Master agent plan + policies in `docs/agent-efficiency/` |
| **Debt** | [/docs/debt/README.md](/docs/debt/README.md) | Open debt register (`debt.md`) + refactor changelog |
| **Operations** | [/docs/ops/public-access.md](/docs/ops/public-access.md) | Observability, public access |
| **E2E / UAT** | [/docs/e2e/uat-deploy-tiers.md](/docs/e2e/uat-deploy-tiers.md) | Live E2E ops, promotion manuals |
| **Design** | [/docs/design/system.md](/docs/design/system.md) | Operations Desk visual spec (canonical) |
| **Database** | [/docs/db/README.md](/docs/db/README.md) | Schema and migration index |
| **Documentation** | [/docs/domains/documentation/standards.md](/docs/domains/documentation/standards.md) | Doc structure and enforcement |
| **Navigation** | [/docs/domains/navigation/README.md](/docs/domains/navigation/README.md) | Shell and routing UX |
| **Cross-domain** | [/docs/domains/cross-domain/README.md](/docs/domains/cross-domain/README.md) | Shared requirements, sprint execution plans |

---

## Navigation & cross-domain delivery

Navigation shell reversal and phased delivery (formerly `docs/experience-program/`).

| Document | Purpose | Status |
|----------|---------|--------|
| [/docs/domains/navigation/README.md](/docs/domains/navigation/README.md) | **Start here** — decision index, briefs, phase 0–1 | Active |
| [/docs/domains/navigation/features/navigation-decisions.md](/docs/domains/navigation/features/navigation-decisions.md) | Shell decisions D1–D6, D27 | Active |
| [/docs/domains/cross-domain/changes/program-contract.md](/docs/domains/cross-domain/changes/program-contract.md) | Cross-cutting contracts and vocabulary | Active |
| [/docs/domains/cross-domain/changes/roadmap-delivery-plan.md](/docs/domains/cross-domain/changes/roadmap-delivery-plan.md) | Phase order and sprint breakdown | Active |
| [/docs/domains/navigation/changes/phase-r-reconciliation.md](/docs/domains/navigation/changes/phase-r-reconciliation.md) | Cleanup of legacy navigation work | Active |
| [/docs/domains/navigation/changes/phase-0-foundation.md](/docs/domains/navigation/changes/phase-0-foundation.md) | Shared primitives and scaffolding | Active |
| [/docs/domains/navigation/changes/phase-1-navigation.md](/docs/domains/navigation/changes/phase-1-navigation.md) | Drawer, header, notifications | Active |

**Domain decisions** (split from former decisions log):

| Domain | File | IDs |
|--------|------|-----|
| Notifications | [/docs/domains/notifications/features/notification-decisions.md](/docs/domains/notifications/features/notification-decisions.md) | D7–D11 |
| Pet profile | [/docs/domains/pet_profile/features/pet-profile-decisions.md](/docs/domains/pet_profile/features/pet-profile-decisions.md) | D17–D24, D34–D37 |
| Shelter | [/docs/domains/shelter/features/shelter-decisions.md](/docs/domains/shelter/features/shelter-decisions.md) | D12–D16, D20–D31, D-v2–v4 |
| Cross-domain | [/docs/domains/cross-domain/changes/delivery-decisions.md](/docs/domains/cross-domain/changes/delivery-decisions.md) | D32–D33 |

**Domain delivery plans:**

| Domain | Plans index |
|--------|-------------|
| Pet profile / Pet Care | [/docs/domains/pet_profile/changes/plans.md](/docs/domains/pet_profile/changes/plans.md) |
| Shelter | [/docs/domains/shelter/changes/plans.md](/docs/domains/shelter/changes/plans.md) |
| Fostering | [/docs/domains/fostering/changes/plans.md](/docs/domains/fostering/changes/plans.md) |

**Locked briefs:**

- [/docs/domains/navigation/features/navigation-brief.md](/docs/domains/navigation/features/navigation-brief.md)
- [/docs/domains/pet_profile/features/guardian-dashboard-brief.md](/docs/domains/pet_profile/features/guardian-dashboard-brief.md)
- [/docs/domains/shelter/features/shelter-dashboard-brief.md](/docs/domains/shelter/features/shelter-dashboard-brief.md)
- [/docs/domains/pet_profile/changes/guardian-ui-wave2-issue-briefs.md](/docs/domains/pet_profile/changes/guardian-ui-wave2-issue-briefs.md)

### Architecture

| Document | Purpose | Status |
|----------|---------|--------|
| [/docs/architecture/index.md](/docs/architecture/index.md) | **Start here** - Domain to code mapping | Active |
| [/docs/architecture/modularity.md](/docs/architecture/modularity.md) | Clean architecture principles | Active |
| [/docs/domains/shelter/features/org-custody-model.md](/docs/domains/shelter/features/org-custody-model.md) | Pet custody and transfer model | Active |
| [/docs/domains/shelter/features/org-member-privacy.md](/docs/domains/shelter/features/org-member-privacy.md) | Per-shelter privacy rules | Active |
| [/docs/architecture/pet-activity-model.md](/docs/architecture/pet-activity-model.md) | Pet activity tracking and timeline | Active |

### Design

| Document | Purpose | Status |
|----------|---------|--------|
| [/docs/design/index.md](/docs/design/index.md) | Design system overview | Active |
| [/docs/design/principles.md](/docs/design/principles.md) | Core design principles | Active |
| [/docs/design/tokens.md](/docs/design/tokens.md) | Design tokens and theming | Active |
| [/docs/design/copy-tone.md](/docs/design/copy-tone.md) | Writing style and tone guide | Active |
| [/docs/design/skin-change-guide.md](/docs/design/skin-change-guide.md) | Theming and branding customization | Active |
| [/docs/design/plans/ui-rework-plan.md](/docs/design/plans/ui-rework-plan.md) | Comprehensive UI overhaul plan | Active |

### Testing & Quality

| Document | Purpose | Status |
|----------|---------|--------|
| [/e2e/README.md](/e2e/README.md) | Playwright E2E test suite | Active |
| [/docs/e2e/navigation-contract.md](/docs/e2e/navigation-contract.md) | Page object action contracts | Active |
| [/docs/pipelines/e2e-ci-canary-plan.md](/docs/pipelines/e2e-ci-canary-plan.md) | Canary deployment strategy | Active |
| [/docs/e2e/uat-deploy-tiers.md](/docs/e2e/uat-deploy-tiers.md) | UAT deployment tier definitions | Active |
| [/docs/e2e/uat-live-operations-runbook.md](/docs/e2e/uat-live-operations-runbook.md) | Live UAT troubleshooting | Active |
| [/docs/e2e/uat-promote-manual.md](/docs/e2e/uat-promote-manual.md) | Manual promotion workflow | Active |
| [/docs/e2e/uat-agent-babysit.md](/docs/e2e/uat-agent-babysit.md) | Agent UAT monitoring | Active |
| [/docs/e2e/uat-demo-data.md](/docs/e2e/uat-demo-data.md) | Test data for UAT | Active |
| [/docs/e2e/uat-demo-personas.md](/docs/e2e/uat-demo-personas.md) | User personas for testing | Active |
| [/docs/e2e/uat-waf-queue-lessons.md](/docs/e2e/uat-waf-queue-lessons.md) | Jul 2026 incident postmortem | Active |
| [/docs/quality/bdd-journey-matrix.md](/docs/quality/bdd-journey-matrix.md) | Gherkin scenario coverage mapping | Active |
| [/docs/quality/scorecard.md](/docs/quality/scorecard.md) | Project health metrics | Active |

### Agent Efficiency

| Document | Purpose | Status |
|----------|---------|--------|
| [/docs/agent-efficiency/plans/agent-efficiency-plan.md](/docs/agent-efficiency/plans/agent-efficiency-plan.md) | **Start here** - Master plan for agent improvements | Active |
| [/docs/agent-efficiency/atomic-pr-policy.md](/docs/agent-efficiency/atomic-pr-policy.md) | One outcome per PR rules | Active |
| [/docs/agent-efficiency/autonomous-pr-policy.md](/docs/agent-efficiency/autonomous-pr-policy.md) | Multi-phase plan autonomy rules | Active |
| [/docs/agent-efficiency/execute-plan-runtime.md](/docs/agent-efficiency/execute-plan-runtime.md) | Plan execution engine | Active |
| [/docs/agent-efficiency/execute-plan-schema.md](/docs/agent-efficiency/execute-plan-schema.md) | Plan artifact schema | Active |
| [/docs/agent-efficiency/phase-exit-checklists.md](/docs/agent-efficiency/phase-exit-checklists.md) | Phase completion criteria | Active |
| [/docs/agent-efficiency/plan-template.md](/docs/agent-efficiency/plan-template.md) | Standard plan structure | Active |
| [/docs/agent-efficiency/prompt-templates.md](/docs/agent-efficiency/prompt-templates.md) | Copy-paste spawn prompts | Active |
| [/docs/agent-efficiency/pr-review-cost-efficiency.md](/docs/agent-efficiency/pr-review-cost-efficiency.md) | Review workflow optimization | Active |
| [/docs/agent-efficiency/uat-coordinator-bootstrap.md](/docs/agent-efficiency/uat-coordinator-bootstrap.md) | UAT coordination setup | Active |
| [/docs/agent-efficiency/uat-coordinator-plan.md](/docs/agent-efficiency/uat-coordinator-plan.md) | UAT agent coordination | Active |
| [/docs/agent-efficiency/github-labels.md](/docs/agent-efficiency/github-labels.md) | Issue label taxonomy | Active |

### Operations

| Document | Purpose | Status |
|----------|---------|--------|
| [/docs/ops/public-access.md](/docs/ops/public-access.md) | Public-facing feature access rules | Active |

---

## Project Management

| Document | Purpose | Status |
|----------|---------|--------|
| [/docs/agent-efficiency/github-issue-workflow.md](/docs/agent-efficiency/github-issue-workflow.md) | Issue lifecycle and triage | Active |
| **Open debt** | [/docs/debt/debt.md](/docs/debt/debt.md) | Single register — OPEN items only |
| [/docs/debt/refactoring-log.md](/docs/debt/refactoring-log.md) | Sprint refactor history (completed work) | Active |
| [/docs/debt/refactoring-log.md](/docs/debt/refactoring-log.md) | Completed refactoring work | Active |
| [/docs/domains/cross-domain/changes/sprint-6-execution-plan.md](/docs/domains/cross-domain/changes/sprint-6-execution-plan.md) | Sprint 6 deliverables | Active |
| [/docs/domains/cross-domain/changes/sprint-10-flutter-344-execution-plan.md](/docs/domains/cross-domain/changes/sprint-10-flutter-344-execution-plan.md) | Flutter 3.44 upgrade plan | Active |
| [/docs/domains/cross-domain/changes/docs-domain-audit-63ad.md](/docs/domains/cross-domain/changes/docs-domain-audit-63ad.md) | Full `.md` inventory audit (wave 3) | Active |
| [/docs/pipelines/ci-build-artifact-contract.md](/docs/pipelines/ci-build-artifact-contract.md) | Build artifact specifications | Active |
| [/docs/pipelines/promotion-contract.md](/docs/pipelines/promotion-contract.md) | UAT to PROD promotion rules | Active |
| [/docs/pipelines/db-schema-bootstrap-plan.md](/docs/pipelines/db-schema-bootstrap-plan.md) | Database initialization | Active |
| [/docs/pipelines/uat-backend-node-modules-runbook.md](/docs/pipelines/uat-backend-node-modules-runbook.md) | UAT backend node modules guide | Active |

---

## Agent-Specific Resources

Agent-focused documentation and skills:

| Location | Purpose |
|----------|---------|
| [/.cursor/skills/](/.cursor/skills/) | Reusable agent skills (split screens, BDD, etc.) |
| [/.cursor/commands/](/.cursor/commands/) | Agent command definitions |
| [/.cursor/BUGBOT.md](/.cursor/BUGBOT.md) | BugBot configuration |
| [/AGENTS.md](/AGENTS.md) | Agent quick-start and workflows |

---

## Historical / Archived Documentation

> These documents are kept for historical reference only.
> They have been superseded by newer documentation or are point-in-time snapshots.

See [/docs/archived/README.md](/docs/archived/README.md) for the full list.

### Key Archived Documents
- [/docs/archived/navigation-v2.md](/docs/archived/navigation-v2.md) - Superseded by [navigation domain](/docs/domains/navigation/README.md)
- [/docs/archived/experience-split-plan.md](/docs/archived/experience-split-plan.md) - Superseded by [Phase R](/docs/domains/navigation/changes/phase-r-reconciliation.md)
- [/docs/archived/quality-review-2026-07-08.md](/docs/archived/quality-review-2026-07-08.md) - Point-in-time snapshot

---

## How to Use This Documentation

### For Humans
1. Start with the [Project README](/README.md) for an overview
2. Use this `docs/README.md` to find specific documentation
3. Check [Architecture Index](/docs/architecture/index.md) for code organization
4. See [Contributing Guide](/CONTRIBUTING.md) for contribution guidelines

### For Agents
1. Start with [Agent Guide](/AGENTS.md) for agent-specific setup
2. Use [Architecture Index](/docs/architecture/index.md) for domain mapping
3. Check [Agent Efficiency Plan](/docs/agent-efficiency/plans/agent-efficiency-plan.md) for workflows
4. Reference [.cursor/skills/](/.cursor/skills/) for reusable skills

### Quick Links by Task

| Task | Start Here |
|------|------------|
| **New to the project?** | [README](/README.md) |
| **Setting up locally?** | [README](/README.md#getting-started) |
| **Adding a feature?** | [Architecture Index](/docs/architecture/index.md) |
| **Running tests?** | [Contributing Guide](/CONTRIBUTING.md#pre-push-checklist) |
| **Agent workflow?** | [Agent Guide](/AGENTS.md) |
| **API changes?** | [API Reference](/API.md) |
| **UAT deployment?** | [E2E README](/e2e/README.md) |
| **Org/foster features?** | [Fostering domain](/docs/domains/fostering/README.md) |
| **UI/UX changes?** | [Design Index](/docs/design/index.md) |

---

## Documentation Conventions

### Metadata Headers
All documentation files in this directory include YAML metadata headers:

```yaml
---
title: Document Title
owner: Team/Person
audience: human|agent|both
status: active|deprecated|superseded|draft
last_updated: YYYY-MM-DD
tags: [comma, separated, tags]
---
```

### Cross-References
- Use **absolute paths** from the repository root (e.g., `/docs/file.md`)
- Use **consistent link format**: `[description](path)`
- Include a **Related** section at the bottom of each document

### Status Labels
| Label | Meaning |
|-------|---------|
| Active | Current, maintained, and up-to-date |
| Superseded | Replaced by newer documentation |
| Deprecated | No longer relevant, will be removed |
| Draft | Work in progress |

---

## Contributing to Documentation

### Adding New Documentation
1. Create the file in the appropriate subdirectory
2. Add a YAML metadata header
3. Add the file to this `README.md` in the appropriate section
4. Update any related documentation with cross-references
5. Run `scripts/validate_docs.sh` to check for issues

### Updating Existing Documentation
1. Update the file content
2. Update the `last_updated` date in the metadata header
3. Verify all cross-references are still valid
4. Run `scripts/validate_docs.sh`

### Archiving Documentation
1. Move the file to `docs/archived/`
2. Add a deprecation notice at the top of the file
3. Update this `README.md` to mark it as archived
4. Update all cross-references to point to the new location

---

## Need Help?

- **General questions**: Check [README](/README.md) or open a GitHub issue
- **Agent-specific questions**: See [Agent Guide](/AGENTS.md)
- **Documentation issues**: Open an issue with the `documentation` label
- **Broken links**: Run `scripts/validate_docs.sh` and fix any errors

---

*Last updated: 2026-08-23*
