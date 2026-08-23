#!/usr/bin/env node
/**
 * Add YAML frontmatter to docs missing headers (wave 4).
 * Usage: node scripts/add_docs_frontmatter_wave4.js [--dry-run]
 */
'use strict';

const fs = require('fs');
const path = require('path');

const REPO = path.resolve(__dirname, '..');

const FILE_META = {
  'docs/plans/sprint-6-execution-plan.md': {
    title: 'Sprint 6 execution plan',
    tags: ['plans', 'sprint', 'bdd'],
  },
  'docs/plans/sprint-10-flutter-344-execution-plan.md': {
    title: 'Sprint 10 Flutter 3.44 execution plan',
    tags: ['plans', 'sprint', 'flutter'],
  },
  'docs/agent-efficiency/plans/agent-efficiency-plan.md': {
    title: 'Agent efficiency plan',
    tags: ['agent', 'workflow'],
  },
  'docs/debt/refactoring-log.md': {
    title: 'Refactoring log',
    tags: ['refactoring', 'sprint'],
  },
  'docs/debt/refactoring-debt.md': {
    title: 'Refactoring debt tracker',
    tags: ['debt', 'refactoring'],
  },
  'docs/debt/technical-debt.md': {
    title: 'Technical debt index',
    tags: ['debt', 'technical'],
  },
  'docs/architecture/api-reference.md': {
    title: 'API reference (docs index)',
    tags: ['api', 'reference'],
  },
  'docs/pipelines/ci-cd-gates.md': {
    title: 'CI/CD gates',
    tags: ['ci', 'gates'],
  },
  'docs/pipelines/ci-cd-baseline.md': {
    title: 'CI/CD baseline metrics',
    tags: ['ci', 'metrics'],
    skip: true,
  },
  'docs/pipelines/db-schema-bootstrap-plan.md': {
    title: 'Database schema bootstrap plan',
    tags: ['database', 'bootstrap'],
  },
  'docs/pipelines/e2e-ci-canary-plan.md': {
    title: 'E2E CI canary plan',
    tags: ['e2e', 'ci', 'canary'],
  },
  'docs/e2e/navigation-contract.md': {
    title: 'E2E navigation contract',
    tags: ['e2e', 'navigation', 'playwright'],
  },
  'docs/pipelines/promotion-contract.md': {
    title: 'UAT promotion contract',
    tags: ['uat', 'promotion'],
  },
  'docs/architecture/index.md': {
    title: 'Architecture index',
    tags: ['architecture', 'index'],
  },
  'docs/architecture/modularity.md': {
    title: 'Modularity conventions',
    tags: ['architecture', 'modularity'],
  },
  'docs/quality/scorecard.md': {
    title: 'Quality scorecard',
    tags: ['quality', 'metrics'],
  },
  'docs/quality/bdd-journey-matrix.md': {
    title: 'BDD journey matrix',
    tags: ['quality', 'bdd'],
  },
  'docs/ops/public-access.md': {
    title: 'Public access rules',
    tags: ['ops', 'public-access'],
  },
  'docs/experience-program/decisions-log.md': {
    title: 'Experience program decisions log',
    tags: ['experience', 'decisions'],
  },
  'docs/experience-program/program-contract.md': {
    title: 'Experience program contract',
    tags: ['experience', 'contract'],
  },
  'docs/experience-program/roadmap-delivery-plan.md': {
    title: 'Experience program roadmap',
    tags: ['experience', 'roadmap'],
  },
  'docs/e2e/uat-demo-data.md': {
    title: 'UAT demo data',
    tags: ['e2e', 'uat', 'demo'],
  },
  'docs/e2e/uat-promote-manual.md': {
    title: 'UAT promote manual',
    tags: ['e2e', 'uat', 'promotion'],
  },
  'docs/e2e/uat-agent-babysit.md': {
    title: 'UAT agent babysit',
    tags: ['e2e', 'uat', 'agent'],
  },
  'docs/e2e/uat-live-operations-runbook.md': {
    title: 'UAT live operations runbook',
    tags: ['e2e', 'uat', 'runbook'],
  },
  'docs/e2e/uat-waf-queue-lessons.md': {
    title: 'UAT WAF queue lessons',
    tags: ['e2e', 'uat', 'incident'],
  },
  'docs/e2e/uat-deploy-tiers.md': {
    title: 'UAT deploy tiers',
    tags: ['e2e', 'uat', 'deploy'],
  },
  'docs/design/ui-rework-plan.md': {
    title: 'UI rework plan',
    tags: ['design', 'ui'],
  },
  'docs/domains/pet_profile/features/pet-activity-model.md': {
    title: 'Pet activity model',
    tags: ['domain', 'pet_profile', 'specs'],
  },
  'docs/domains/pet_profile/changes/guardian-ui-wave2-issue-briefs.md': {
    title: 'Guardian UI wave 2 issue briefs',
    tags: ['domain', 'pet_profile', 'plans'],
  },
  'docs/domains/organization/changes/organisation-people-permissions-v4-delivery-plan.md': {
    title: 'Organisation people permissions v4 delivery plan',
    tags: ['domain', 'organization', 'plans'],
  },
  'docs/domains/organization/changes/organisation-v2-delivery-plan.md': {
    title: 'Organisation v2 delivery plan',
    tags: ['domain', 'organization', 'plans'],
  },
  'docs/domains/organization/changes/organisation-ux-v3-delivery-plan.md': {
    title: 'Organisation UX v3 delivery plan',
    tags: ['domain', 'organization', 'plans'],
  },
  'docs/domains/fostering/features/g0-contract-pack.md': {
    title: 'Fostering G0 contract pack',
    tags: ['domain', 'fostering', 'specs'],
  },
  'docs/domains/fostering/features/migration-appendix.md': {
    title: 'Fostering migration appendix',
    tags: ['domain', 'fostering', 'specs'],
  },
  'docs/domains/fostering/changes/roadmap-delivery-plan.md': {
    title: 'Fostering roadmap delivery plan',
    tags: ['domain', 'fostering', 'plans'],
  },
  'docs/domains/fostering/changes/org-fostering-strategy.md': {
    title: 'Organisation fostering strategy',
    tags: ['domain', 'fostering', 'plans'],
  },
};

const AGENT_EFFICIENCY_FILES = [
  'atomic-pr-policy.md',
  'autonomous-pr-policy.md',
  'execute-plan-schema.md',
  'execute-plan-runtime.md',
  'phase-exit-checklists.md',
  'plan-template.md',
  'prompt-templates.md',
  'pr-review-cost-efficiency.md',
  'uat-coordinator-plan.md',
  'uat-coordinator-bootstrap.md',
  'github-labels.md',
];

for (const f of AGENT_EFFICIENCY_FILES) {
  const rel = `docs/agent-efficiency/${f}`;
  const title = f
    .replace(/\.md$/, '')
    .replace(/-/g, ' ')
    .replace(/\b\w/g, (c) => c.toUpperCase());
  FILE_META[rel] = { title, tags: ['agent-efficiency', 'policy'] };
}

function buildHeader(rel, meta) {
  const tags = meta.tags || ['documentation'];
  return [
    '---',
    `title: ${meta.title}`,
    'owner: Documentation Team',
    'audience: both',
    'status: active',
    'last_updated: 2026-08-22',
    `tags: [${tags.join(', ')}]`,
    '---',
    '',
  ].join('\n');
}

const dryRun = process.argv.includes('--dry-run');
let updated = 0;

for (const [rel, meta] of Object.entries(FILE_META)) {
  if (meta.skip) continue;
  const abs = path.join(REPO, rel);
  if (!fs.existsSync(abs)) {
    console.warn(`skip missing: ${rel}`);
    continue;
  }
  const content = fs.readFileSync(abs, 'utf8');
  if (content.startsWith('---')) continue;
  const newContent = buildHeader(rel, meta) + content;
  if (dryRun) {
    console.log(`would update: ${rel}`);
  } else {
    fs.writeFileSync(abs, newContent);
    console.log(`updated: ${rel}`);
  }
  updated += 1;
}

console.log(`${dryRun ? 'would update' : 'updated'} ${updated} file(s)`);
