#!/usr/bin/env node
/**
 * Plan or print cheap-gate parity line for pre-push-changed.sh.
 *
 *   node scripts/ci/prepush-parity-summary.mjs --plan --flutter 1 --governance 1 --docs 0
 *   node scripts/ci/prepush-parity-summary.mjs --emit --run 4 --total 5 --sha abc1234
 */
import { cheapGatesForPrepush } from './governance-gate-lib.mjs';

function flag(name) {
  const i = process.argv.indexOf(name);
  if (i === -1) return false;
  return process.argv[i + 1] === '1' || process.argv[i + 1] === 'true';
}

function opt(name) {
  const i = process.argv.indexOf(name);
  return i >= 0 ? process.argv[i + 1] : '';
}

function main() {
  if (process.argv.includes('--plan')) {
    const gates = cheapGatesForPrepush({
      needsFlutter: flag('--flutter'),
      needsGovernance: flag('--governance'),
      docsTouched: flag('--docs'),
    });
    console.log(gates.length);
    return;
  }
  if (process.argv.includes('--emit')) {
    const run = Number(opt('--run'));
    const total = Number(opt('--total'));
    const sha = opt('--sha');
    console.log(`parity: ${run}/${total} cheap CI gates run for ${sha}`);
  }
}

main();
