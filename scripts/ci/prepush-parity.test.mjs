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

test('cheap CI run steps in parity workflows map to registry needles', () => {
  const needles = GOVERNANCE_GATE_REGISTRY.filter((g) => g.cheap && g.ci).flatMap(
    (g) => g.ci.runIncludes,
  );
  for (const wfPath of CHEAP_CI_WORKFLOWS) {
    const wf = readWorkflow(wfPath);
    const runs = wf.match(/^\s+run:\s*(.+)$/gm) ?? [];
    for (const line of runs) {
      const cmd = line.replace(/^\s+run:\s*/, '');
      if (!needles.some((n) => cmd.includes(n))) continue;
      const matched = GOVERNANCE_GATE_REGISTRY.some(
        (g) => g.cheap && g.ci?.workflow === wfPath && g.ci.runIncludes.some((n) => cmd.includes(n)),
      );
      assert.ok(matched, `unregistered cheap CI step in ${wfPath}: ${cmd.slice(0, 80)}`);
    }
  }
});

test('pre-push-changed empty-tree parity uses run count for total', () => {
  const script = fs.readFileSync(PREPUSH_SH, 'utf8');
  assert.match(
    script,
    /PARITY_TOTAL="\$PREPUSH_PARITY_RUN"/,
    'empty changed-files path must not inflate parity denominator',
  );
});
