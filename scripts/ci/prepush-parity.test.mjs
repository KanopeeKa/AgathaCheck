import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

import {
  CHEAP_CI_WORKFLOWS,
  GOVERNANCE_GATE_REGISTRY,
} from './governance-blocking-steps.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, '..', '..');
const PREPUSH_SH = path.join(REPO_ROOT, 'scripts/pre-push-changed.sh');

function readWorkflow(relPath) {
  return fs.readFileSync(path.join(REPO_ROOT, relPath), 'utf8');
}

test('every cheap prepush gate documents a CI workflow step', () => {
  for (const gate of GOVERNANCE_GATE_REGISTRY) {
    if (!gate.cheap || !gate.ci || !CHEAP_CI_WORKFLOWS.includes(gate.ci.workflow)) continue;
    const wf = readWorkflow(gate.ci.workflow);
    for (const needle of gate.ci.runIncludes) {
      assert.ok(
        wf.includes(needle),
        `${gate.id}: expected ${needle} in ${gate.ci.workflow}`,
      );
    }
  }
});

test('pre-push-changed.sh invokes run_prepush_gate for each prepush-scoped cheap gate', () => {
  const script = fs.readFileSync(PREPUSH_SH, 'utf8');
  assert.match(script, /run_prepush_gate /, 'pre-push-changed.sh must define run_prepush_gate');
  const prepushIds = GOVERNANCE_GATE_REGISTRY.filter(
    (g) => g.cheap && g.prepush !== 'exempt' && g.prepush !== 'full-only',
  ).map((g) => g.id);
  for (const id of prepushIds) {
    assert.match(
      script,
      new RegExp(`run_prepush_gate[\\s"']+${id.replace(/-/g, '[-]')}`),
      `pre-push-changed.sh must call run_prepush_gate for ${id}`,
    );
  }
});

test('exempt web bundle budget has a reason', () => {
  const gate = GOVERNANCE_GATE_REGISTRY.find((g) => g.id === 'web-bundle-budget');
  assert.ok(gate?.exemptReason && gate.exemptReason.length >= 10);
});
