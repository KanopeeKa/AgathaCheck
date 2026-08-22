---
title: Agatha Track Documentation
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
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
| [/API.md](/API.md) | REST endpoint reference (authoritative) | Both |
| [/docs/ci-cd-baseline.md](/docs/ci-cd-baseline.md) | Pipeline metrics and performance targets | Both |
| [/docs/ci-cd-gates.md](/docs/ci-cd-gates.md) | Blocking vs advisory gates, UAT/PROD rules | Both |
| [/docs/calendar-dates.md](/docs/calendar-dates.md) | `YYYY-MM-DD` wire format specification | Both |

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
| Organization | [/docs/domains/organization/README.md](/docs/domains/organization/README.md) | Org identity, permissions, privacy, custody model |
| Fostering | [/docs/domains/fostering/README.md](/docs/domains/fostering/README.md) | Placements, adoption, custody transfers |
| Subscription | [/docs/domains/subscription/README.md](/docs/domains/subscription/README.md) | Premium tiers (billing TBD) |
| Help & about | [/docs/domains/help_about/README.md](/docs/domains/help_about/README.md) | FAQ and about screens |

Cross-cutting deferred work: [/docs/deferred.md](/docs/deferred.md)

---

## Domain-Specific Documentation (legacy paths)

> **Migration in progress:** content is moving into `docs/domains/` above. Stubs remain at former paths until link pass completes.

### Organization & Fostering (legacy index)

| Document | Purpose | Status |
|----------|---------|--------|
| [/docs/fostering-platform/README.md](/docs/fostering-platform/README.md) | Redirect → [fostering domain](/docs/domains/fostering/README.md) | Superseded |
| [/docs/fostering-platform/g0-contract-pack.md](/docs/fostering-platform/g0-contract-pack.md) | Core fostering workflow contracts | Active |
| [/docs/fostering-platform/j1-foster-onboarding.md](/docs/fostering-platform/j1-foster-onboarding.md) | Foster parent onboarding flow | Active |
| [/docs/fostering-platform/migration-appendix.md](/docs/fostering-platform/migration-appendix.md) | Data migration guides | Active |
| [/docs/fostering-platform/roadmap-delivery-plan.md](/docs/fostering-platform/roadmap-delivery-plan.md) | Fostering platform delivery timeline | Active |
| [/docs/org-fostering-strategy.md](/docs/org-fostering-strategy.md) | Organization roles and permission matrix | Active |

### Experience Program

The **active** program for navigation reversal, Guardian dashboard, and Organisation UX rework.

| Document | Purpose | Status |
|----------|---------|--------|
| [/docs/experience-program/README.md](/docs/experience-program/README.md) | Program overview and document index | Active |
| [/docs/experience-program/decisions-log.md](/docs/experience-program/decisions-log.md) | **Read first** - All product decisions with IDs | Active |
| [/docs/experience-program/program-contract.md](/docs/experience-program/program-contract.md) | Cross-cutting contracts and vocabulary | Active |
| [/docs/experience-program/roadmap-delivery-plan.md](/docs/experience-program/roadmap-delivery-plan.md) | Phase order and sprint breakdown | Active |
| [/docs/experience-program/phase-0-foundation.md](/docs/experience-program/phase-0-foundation.md) | Shared primitives and scaffolding | Active |
| [/docs/experience-program/phase-1-navigation.md](/docs/experience-program/phase-1-navigation.md) | Drawer, header, notifications | Active |
| [/docs/experience-program/phase-2-guardian-journey.md](/docs/experience-program/phase-2-guardian-journey.md) | Guardian dashboard and pet timeline | Active |
| [/docs/experience-program/phase-3-organisation-presentation.md](/docs/experience-program/phase-3-organisation-presentation.md) | Org dashboard and profile composer | Active |
| [/docs/experience-program/phase-4-foster-pet-operations.md](/docs/experience-program/phase-4-foster-pet-operations.md) | Foster self-management | Active |
| [/docs/experience-program/phase-5-organisation-customisations.md](/docs/experience-program/phase-5-organisation-customisations.md) | Templates and permissions admin | Active |
| [/docs/experience-program/phase-5-ui-design-review.md](/docs/experience-program/phase-5-ui-design-review.md) | UI design review | Active |
| [/docs/experience-program/phase-r-reconciliation.md](/docs/experience-program/phase-r-reconciliation.md) | Cleanup of legacy navigation work | Active |
| [/docs/experience-program/organisation-v2-delivery-plan.md](/docs/experience-program/organisation-v2-delivery-plan.md) | Profile composer and view permissions | Active |
| [/docs/experience-program/organisation-ux-v3-delivery-plan.md](/docs/experience-program/organisation-ux-v3-delivery-plan.md) | Show-org, chrome, nav rows, privacy | Active |
| [/docs/experience-program/organisation-people-permissions-v4-delivery-plan.md](/docs/experience-program/organisation-people-permissions-v4-delivery-plan.md) | People directory and staged permissions | **Active (2026-08-06)** |

**Briefs** (Locked product-truth documents):
- [/docs/experience-program/briefs/navigation-brief.md](/docs/experience-program/briefs/navigation-brief.md)
- [/docs/experience-program/briefs/guardian-dashboard-brief.md](/docs/experience-program/briefs/guardian-dashboard-brief.md)
- [/docs/experience-program/briefs/organisation-dashboard-brief.md](/docs/experience-program/briefs/organisation-dashboard-brief.md)
- [/docs/experience-program/briefs/guardian-ui-wave2-issue-briefs.md](/docs/experience-program/briefs/guardian-ui-wave2-issue-briefs.md)

### Architecture

| Document | Purpose | Status |
|----------|---------|--------|
| [/docs/architecture/index.md](/docs/architecture/index.md) | **Start here** - Domain to code mapping | Active |
| [/docs/architecture/modularity.md](/docs/architecture/modularity.md) | Clean architecture principles | Active |
| [/docs/architecture/org-custody-model.md](/docs/architecture/org-custody-model.md) | Pet custody and transfer model | Active |
| [/docs/architecture/org-member-privacy.md](/docs/architecture/org-member-privacy.md) | Per-organization privacy rules | Active |
| [/docs/architecture/pet-activity-model.md](/docs/architecture/pet-activity-model.md) | Pet activity tracking and timeline | Active |

### Design

| Document | Purpose | Status |
|----------|---------|--------|
| [/docs/design/index.md](/docs/design/index.md) | Design system overview | Active |
| [/docs/design/principles.md](/docs/design/principles.md) | Core design principles | Active |
| [/docs/design/tokens.md](/docs/design/tokens.md) | Design tokens and theming | Active |
| [/docs/design/copy-tone.md](/docs/design/copy-tone.md) | Writing style and tone guide | Active |
| [/docs/design/skin-change-guide.md](/docs/design/skin-change-guide.md) | Theming and branding customization | Active |
| [/docs/design/ui-rework-plan.md](/docs/design/ui-rework-plan.md) | Comprehensive UI overhaul plan | Active |

### Testing & Quality

| Document | Purpose | Status |
|----------|---------|--------|
| [/e2e/README.md](/e2e/README.md) | Playwright E2E test suite | Active |
| [/docs/e2e-navigation-contract.md](/docs/e2e-navigation-contract.md) | Page object action contracts | Active |
| [/docs/e2e-ci-canary-plan.md](/docs/e2e-ci-canary-plan.md) | Canary deployment strategy | Active |
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
| [/docs/agent-efficiency-plan.md](/docs/agent-efficiency-plan.md) | **Start here** - Master plan for agent improvements | Active |
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
| [/docs/github-issue-workflow.md](/docs/github-issue-workflow.md) | Issue lifecycle and triage | Active |
| [/docs/technical-debt.md](/docs/technical-debt.md) | Product/infra deferrals (splitting → domains + deferred.md) | Active |
| [/docs/refactoring-debt.md](/docs/refactoring-debt.md) | Refactoring uncertainty log | Active |
| [/docs/refactoring-log.md](/docs/refactoring-log.md) | Completed refactoring work | Active |
| [/docs/sprint-6-execution-plan.md](/docs/sprint-6-execution-plan.md) | Sprint 6 deliverables | Active |
| [/docs/sprint-10-flutter-344-execution-plan.md](/docs/sprint-10-flutter-344-execution-plan.md) | Flutter 3.44 upgrade plan | Active |
| [/docs/ci-build-artifact-contract.md](/docs/ci-build-artifact-contract.md) | Build artifact specifications | Active |
| [/docs/promotion-contract.md](/docs/promotion-contract.md) | UAT to PROD promotion rules | Active |
| [/docs/db-schema-bootstrap-plan.md](/docs/db-schema-bootstrap-plan.md) | Database initialization | Active |
| [/docs/uat-backend-node-modules-runbook.md](/docs/uat-backend-node-modules-runbook.md) | UAT backend node modules guide | Active |

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
- [/docs/archived/navigation-v2.md](/docs/archived/navigation-v2.md) - Superseded by [Experience Program](/docs/experience-program/)
- [/docs/archived/experience-split-plan.md](/docs/archived/experience-split-plan.md) - Superseded by [Phase R](/docs/experience-program/phase-r-reconciliation.md)
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
3. Check [Agent Efficiency Plan](/docs/agent-efficiency-plan.md) for workflows
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
| **Org/foster features?** | [Fostering Platform](/docs/fostering-platform/README.md) |
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

*Last updated: 2026-08-22*
