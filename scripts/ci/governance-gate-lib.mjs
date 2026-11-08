import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { GOVERNANCE_GATE_REGISTRY } from './governance-blocking-steps.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
export const REPO_ROOT = path.resolve(__dirname, '..', '..');

export function gateById(id) {
  const gate = GOVERNANCE_GATE_REGISTRY.find((g) => g.id === id);
  if (!gate) {
    throw new Error(`unknown governance gate id: ${id}`);
  }
  return gate;
}

/** @param {string} id */
export function runGateById(id) {
  const gate = gateById(id);
  const result = spawnSync(gate.command, {
    shell: true,
    cwd: REPO_ROOT,
    stdio: 'inherit',
    env: process.env,
  });
  if (result.error) {
    console.error(`run-governance-gate ${id}: ${result.error.message}`);
    process.exit(1);
  }
  process.exit(result.status === null ? 1 : result.status);
}

/**
 * Cheap gates to run for a pre-push-changed scope (CIPR parity).
 * @param {{ needsFlutter?: boolean, needsGovernance?: boolean, docsTouched?: boolean }} scope
 */
export function cheapGatesForPrepush(scope) {
  const { needsFlutter = false, needsGovernance = false, docsTouched = false } = scope;
  return GOVERNANCE_GATE_REGISTRY.filter((gate) => {
    if (!gate.cheap) return false;
    if (gate.prepush === 'exempt') return false;
    if (gate.prepush === 'full-only') return false;
    if (gate.prepush === 'flutter' && needsFlutter) return true;
    if (gate.prepush === 'governance' && needsGovernance) return true;
    if (gate.prepush === 'docs-strict' && docsTouched) return true;
    return false;
  });
}
