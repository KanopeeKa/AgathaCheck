---
title: Agatha Track Documentation
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-21
tags: [overview,table-of-contents,documentation]
---

# Agatha Track Documentation

> **Master Table of Contents** - Start here for all project documentation

This directory contains all technical and operational documentation for **Agatha Track** (formerly PetProfileApp). Use this file as your entry point to navigate the documentation structure.

---

## 📚 **Core Documentation**

Foundational documents that describe the project's architecture, setup, and workflows.

| Document | Purpose | Audience |
|----------|---------|----------|
| [Architecture Index](architecture/index.md) | Domain map, tech stack, and code organization | Both |
| [API Reference](../API.md) | REST endpoint reference (authoritative) | Both |
| [CI/CD Baseline](ci-cd-baseline.md) | Pipeline metrics and performance targets | Both |
| [CI/CD Gates](ci-cd-gates.md) | Blocking vs advisory gates, UAT/PROD rules | Both |
| [Calendar Dates](calendar-dates.md) | `YYYY-MM-DD` wire format specification | Both |

---

## 🏗️ **Domain-Specific Documentation**

### Organization & Fostering

| Document | Purpose | Status |
|----------|---------|--------|
| [Fostering Platform](fostering-platform/README.md) | Master index for fostering features | Active |
| [G0 Contract Pack](fostering-platform/g0-contract-pack.md) | Core fostering workflow contracts | Active |
| [J1 Foster Onboarding](fostering-platform/j1-foster-onboarding.md) | Foster parent onboarding flow | Active |
| [Migration Appendix](fostering-platform/migration-appendix.md) | Data migration guides | Active |
| [Roadmap Delivery Plan](fostering-platform/roadmap-delivery-plan.md) | Fostering platform delivery timeline | Active |
| [Org Fostering Strategy](../org-fostering-strategy.md) | Organization roles and permission matrix | Active |

### Experience Program

The **active** program for navigation reversal, Guardian dashboard, and Organisation UX rework.

| Document | Purpose | Status |
|----------|---------|--------|
| [README](experience-program/README.md) | Program overview and document index | Active |
| [Decisions Log](experience-program/decisions-log.md) | **Read first** - All product decisions with IDs | Active |
| [Program Contract](experience-program/program-contract.md) | Cross-cutting contracts and vocabulary | Active |
| [Roadmap Delivery Plan](experience-program/roadmap-delivery-plan.md) | Phase order and sprint breakdown | Active |
| [Phase 0: Foundation](experience-program/phase-0-foundation.md) | Shared primitives and scaffolding | Active |
| [Phase 1: Navigation](experience-program/phase-1-navigation.md) | Drawer, header, notifications | Active |
| [Phase 2: Guardian Journey](experience-program/phase-2-guardian-journey.md) | Guardian dashboard and pet timeline | Active |
| [Phase 3: Organisation Presentation](experience-program/phase-3-organisation-presentation.md) | Org dashboard and profile composer | Active |
| [Phase 4: Foster Operations](experience-program/phase-4-foster-pet-operations.md) | Foster self-management | Active |
| [Phase 5: Customisations](experience-program/phase-5-organisation-customisations.md) | Templates and permissions admin | Active |
| [Phase R: Reconciliation](experience-program/phase-r-reconciliation.md) | Cleanup of legacy navigation work | Active |
| [Organisation v2](experience-program/organisation-v2-delivery-plan.md) | Profile composer and view permissions | Active |
| [Organisation UX v3](experience-program/organisation-ux-v3-delivery-plan.md) | Show-org, chrome, nav rows, privacy | Active |
| [People & Permissions v4](experience-program/organisation-people-permissions-v4-delivery-plan.md) | People directory and staged permissions | **Active (2026-08-06)** |

**Briefs** (Locked product-truth documents):
- [Navigation Brief](experience-program/briefs/navigation-brief.md)
- [Guardian Dashboard Brief](experience-program/briefs/guardian-dashboard-brief.md)
- [Organisation Dashboard Brief](experience-program/briefs/organisation-dashboard-brief.md)
- [Guardian UI Wave 2 Issue Briefs](experience-program/briefs/guardian-ui-wave2-issue-briefs.md)

### Architecture

| Document | Purpose | Status |
|----------|---------|--------|
| [Index](architecture/index.md) | **Start here** - Domain to code mapping | Active |
| [Modularity](architecture/modularity.md) | Clean architecture principles | Active |
| [Org Custody Model](architecture/org-custody-model.md) | Pet custody and transfer model | Active |
| [Org Member Privacy](architecture/org-member-privacy.md) | Per-organization privacy rules | Active |
| [Pet Activity Model](architecture/pet-activity-model.md) | Pet activity tracking and timeline | Active |

### Design

| Document | Purpose | Status |
|----------|---------|--------|
| [Index](design/index.md) | Design system overview | Active |
| [Principles](design/principles.md) | Core design principles | Active |
| [Tokens](design/tokens.md) | Design tokens and theming | Active |
| [Copy Tone](design/copy-tone.md) | Writing style and tone guide | Active |
| [Skin Change Guide](design/skin-change-guide.md) | Theming and branding customization | Active |
| [UI Rework Plan](design/ui-rework-plan.md) | Comprehensive UI overhaul plan | Active |

### Testing & Quality

| Document | Purpose | Status |
|----------|---------|--------|
| [E2E README](../e2e/README.md) | Playwright E2E test suite | Active |
| [E2E Navigation Contract](e2e-navigation-contract.md) | Page object action contracts | Active |
| [E2E CI Canary Plan](e2e-ci-canary-plan.md) | Canary deployment strategy | Active |
| [UAT Deploy Tiers](e2e/uat-deploy-tiers.md) | UAT deployment tier definitions | Active |
| [UAT Live Operations Runbook](e2e/uat-live-operations-runbook.md) | Live UAT troubleshooting | Active |
| [UAT Promote Manual](e2e/uat-promote-manual.md) | Manual promotion workflow | Active |
| [UAT Agent Babysit](e2e/uat-agent-babysit.md) | Agent UAT monitoring | Active |
| [UAT Demo Data](e2e/uat-demo-data.md) | Test data for UAT | Active |
| [UAT Demo Personas](e2e/uat-demo-personas.md) | User personas for testing | Active |
| [UAT WAF Queue Lessons](e2e/uat-waf-queue-lessons.md) | Jul 2026 incident postmortem | Active |
| [BDD Journey Matrix](quality/bdd-journey-matrix.md) | Gherkin scenario coverage mapping | Active |
| [Scorecard](quality/scorecard.md) | Project health metrics | Active |

### Agent Efficiency

| Document | Purpose | Status |
|----------|---------|--------|
| [Agent Efficiency Plan](agent-efficiency-plan.md) | **Start here** - Master plan for agent improvements | Active |
| [Atomic PR Policy](agent-efficiency/atomic-pr-policy.md) | One outcome per PR rules | Active |
| [Autonomous PR Policy](agent-efficiency/autonomous-pr-policy.md) | Multi-phase plan autonomy rules | Active |
| [Execute Plan Runtime](agent-efficiency/execute-plan-runtime.md) | Plan execution engine | Active |
| [Execute Plan Schema](agent-efficiency/execute-plan-schema.md) | Plan artifact schema | Active |
| [Phase Exit Checklists](agent-efficiency/phase-exit-checklists.md) | Phase completion criteria | Active |
| [Plan Template](agent-efficiency/plan-template.md) | Standard plan structure | Active |
| [Prompt Templates](agent-efficiency/prompt-templates.md) | Copy-paste spawn prompts | Active |
| [PR Review Cost Efficiency](agent-efficiency/pr-review-cost-efficiency.md) | Review workflow optimization | Active |
| [UAT Coordinator Bootstrap](agent-efficiency/uat-coordinator-bootstrap.md) | UAT coordination setup | Active |
| [UAT Coordinator Plan](agent-efficiency/uat-coordinator-plan.md) | UAT agent coordination | Active |
| [GitHub Labels](agent-efficiency/github-labels.md) | Issue label taxonomy | Active |

### Operations

| Document | Purpose | Status |
|----------|---------|--------|
| [Public Access](ops/public-access.md) | Public-facing feature access rules | Active |

---

## 📋 **Project Management**

| Document | Purpose | Status |
|----------|---------|--------|
| [GitHub Issue Workflow](github-issue-workflow.md) | Issue lifecycle and triage | Active |
| [Technical Debt](technical-debt.md) | Product/infra deferrals | Active |
| [Refactoring Debt](refactoring-debt.md) | Refactoring uncertainty log | Active |
| [Refactoring Log](refactoring-log.md) | Completed refactoring work | Active |
| [Sprint 6 Execution Plan](sprint-6-execution-plan.md) | Sprint 6 deliverables | Active |
| [Sprint 10 Execution Plan](sprint-10-flutter-344-execution-plan.md) | Flutter 3.44 upgrade plan | Active |
| [CI Build Artifact Contract](ci-build-artifact-contract.md) | Build artifact specifications | Active |
| [Promotion Contract](promotion-contract.md) | UAT to PROD promotion rules | Active |
| [DB Schema Bootstrap Plan](db-schema-bootstrap-plan.md) | Database initialization | Active |

---

## 🤖 **Agent-Specific Resources**

Agent-focused documentation and skills:

| Location | Purpose |
|----------|---------|
| [.cursor/skills/](../../.cursor/skills/) | Reusable agent skills (split screens, BDD, etc.) |
| [.cursor/commands/](../../.cursor/commands/) | Agent command definitions |
| [.cursor/BUGBOT.md](../../.cursor/BUGBOT.md) | BugBot configuration |
| [AGENTS.md](../AGENTS.md) | Agent quick-start and workflows |

---

## 📅 **Historical / Archived Documentation**

> ⚠️ **These documents are kept for historical reference only.**
> They have been superseded by newer documentation or are point-in-time snapshots.

See [docs/archived/README.md](archived/README.md) for the full list.

### Key Archived Documents
- [Navigation v2](archived/navigation-v2.md) → Superseded by [Experience Program](experience-program/)
- [Experience Split Plan](archived/experience-split-plan.md) → Superseded by [Phase R](experience-program/phase-r-reconciliation.md)
- [Quality Review 2026-07-08](archived/quality-review-2026-07-08.md) → Point-in-time snapshot

---

## 🔍 **How to Use This Documentation**

### For Humans
1. Start with the **[Project README](../README.md)** for an overview
2. Use this **`docs/README.md`** to find specific documentation
3. Check **[Architecture Index](architecture/index.md)** for code organization
4. See **[CONTRIBUTING.md](../CONTRIBUTING.md)** for contribution guidelines

### For Agents
1. Start with **[AGENTS.md](../AGENTS.md)** for agent-specific setup
2. Use **[Architecture Index](architecture/index.md)** for domain mapping
3. Check **[Agent Efficiency Plan](agent-efficiency-plan.md)** for workflows
4. Reference **[.cursor/skills/](../../.cursor/skills/)** for reusable skills

### Quick Links by Task

| Task | Start Here |
|------|------------|
| **New to the project?** | [README](../README.md) |
| **Setting up locally?** | [README](../README.md#getting-started) |
| **Adding a feature?** | [Architecture Index](architecture/index.md) |
| **Running tests?** | [CONTRIBUTING.md](../CONTRIBUTING.md#pre-push-checklist) |
| **Agent workflow?** | [AGENTS.md](../AGENTS.md) |
| **API changes?** | [API Reference](../API.md) |
| **UAT deployment?** | [E2E README](../e2e/README.md) |
| **Org/foster features?** | [Fostering Platform](fostering-platform/README.md) |
| **UI/UX changes?** | [Design Index](design/index.md) |

---

## 📝 **Documentation Conventions**

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
- Include a **"Related" section** at the bottom of each document

### Status Labels
| Label | Meaning |
|-------|---------|
| ✅ Active | Current, maintained, and up-to-date |
| ⚠️ Superseded | Replaced by newer documentation |
| 🗑️ Deprecated | No longer relevant, will be removed |
| 📝 Draft | Work in progress |

---

## 🤝 **Contributing to Documentation**

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

## 📞 **Need Help?**

- **General questions**: Check [README](../README.md) or open a GitHub issue
- **Agent-specific questions**: See [AGENTS.md](../AGENTS.md)
- **Documentation issues**: Open an issue with the `documentation` label
- **Broken links**: Run `scripts/validate_docs.sh` and fix any errors

---

*Last updated: 2026-08-21*
