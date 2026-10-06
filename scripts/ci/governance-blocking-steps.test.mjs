import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

import {
  BLOCKING_GOVERNANCE_STEPS,
  CI_GATE_REQUIRED_CALLERS,
} from './governance-blocking-steps.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, '..', '..');

function readWorkflow(relPath) {
  return fs.readFileSync(path.join(REPO_ROOT, relPath), 'utf8');
}

function jobSectionById(workflowText, jobId) {
  const start = workflowText.indexOf(`  ${jobId}:`);
  assert.ok(start >= 0, `job id ${jobId} not found in workflow`);
  const tail = workflowText.slice(start + 1);
  const nextJob = tail.match(/\n  [a-z0-9-]+:\n/);
  const end = nextJob ? start + 1 + nextJob.index : workflowText.length;
  return workflowText.slice(start, end);
}

function stepRunsBlocking(section, runIncludes, runExcludes = []) {
  const lines = section.split('\n');
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (!line.includes('run:')) continue;
    const runLine = line.includes('run: |')
      ? lines.slice(i, i + 12).join('\n')
      : line;
    if (!runIncludes.every((needle) => runLine.includes(needle))) continue;
    if (runExcludes.some((needle) => runLine.includes(needle))) continue;
    const block = lines.slice(Math.max(0, i - 6), i + 8).join('\n');
    assert.doesNotMatch(
      block,
      /continue-on-error:\s*true/,
      `blocking step must not use continue-on-error: ${runIncludes.join(', ')}`,
    );
    return true;
  }
  return false;
}

test('each governance gate is a blocking CI step in the required workflows', () => {
  for (const step of BLOCKING_GOVERNANCE_STEPS) {
    const workflow = readWorkflow(step.ci.workflow);
    const section = jobSectionById(workflow, step.ci.jobId);
    assert.ok(
      stepRunsBlocking(section, step.ci.runIncludes, step.ci.runExcludes ?? []),
      `${step.id}: expected blocking run containing ${step.ci.runIncludes.join(' + ')} in ${step.ci.workflow} job ${step.ci.jobId}`,
    );
  }
});

test('ci-gate aggregates test-suite and flutter-coverage (coverage gates block merge)', () => {
  const ciYml = readWorkflow('.github/workflows/ci.yml');
  for (const job of ['test-suite', 'flutter-coverage']) {
    assert.match(ciYml, new RegExp(`\\n\\s+${job}:\\n`));
    assert.match(ciYml, new RegExp(`-\\s+${job}\\s*\\n`), `ci-gate needs must include ${job}`);
  }
  for (const job of CI_GATE_REQUIRED_CALLERS) {
    assert.match(
      readWorkflow('scripts/ci/assert-ci-gate.sh'),
      new RegExp(`\\[${job.replace(/-/g, '\\-')}\\]`),
      `assert-ci-gate.sh must track ${job}`,
    );
  }
});
