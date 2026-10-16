'use strict';

const fs = require('fs');
const path = require('path');

const DIR = path.join(__dirname, '..', 'fixtures', 'execute-plan-v2', 'scenarios');

// contracts §3.8
const DEFAULT_CONFIG = {
  owners: ['KanopeeKa'],
  bot_login: 'pawpet-bot',
  cursor_model_implement: 'model-placeholder',
  cursor_model_fix: 'model-placeholder',
  required_checks: {
    integration: ['ci-gate / CI passed', 'execute-plan-scope'],
    main: ['Analyze JavaScript', 'ci-gate / CI passed', 'execute-plan-scope'],
  },
  uat: {
    preuat_workflow: 'pre-uat-e2e.yml',
    preuat_gate_job: 'Pre-UAT E2E gate',
    promote_workflow: 'promote-uat.yml',
    deploy_workflow: 'deploy-uat.yml',
    deploy_proof_job: 'Prod ready',
    deploy_job: 'Build and deploy to UAT',
    smoke_job: 'UAT post-deploy smoke',
    tier3_workflow: 'uat-live-e2e.yml',
    tag_pattern: '^uat-(\\d{6})-(\\d+)$',
  },
};

const isObj = (v) => v !== null && typeof v === 'object' && !Array.isArray(v);

/** Plain objects merge key by key; arrays and scalars replace. */
function deepMerge(base, patch) {
  if (!isObj(base) || !isObj(patch)) return patch === undefined ? base : patch;
  const out = { ...base };
  for (const k of Object.keys(patch)) out[k] = k in base ? deepMerge(base[k], patch[k]) : patch[k];
  return out;
}

const read = (name) => JSON.parse(fs.readFileSync(path.join(DIR, name), 'utf8'));

/** Every `pr` in the patch is merged onto _base.pr.json first; `uat` onto _base.uat.json. */
function withPrBases(patch, basePr, baseUat) {
  const p = JSON.parse(JSON.stringify(patch || {}));
  const fix = (o, key) => { if (o && isObj(o[key])) o[key] = deepMerge(basePr, o[key]); };
  (p.phases || []).forEach((ph) => fix(ph, 'pr'));
  fix(p.sync, 'open_pr');
  fix(p.release, 'pr');
  fix(p.remedial, 'open_pr');
  if (isObj(p.uat)) p.uat = deepMerge(baseUat, p.uat);
  return p;
}

function buildBase(scenario = {}) {
  const basePr = read('_base.pr.json');
  const baseUat = read('_base.uat.json');
  const snapshot = deepMerge(read('_base.snapshot.json'), scenario.snapshot_patch || {});
  const obs = deepMerge(read('_base.observations.json'), withPrBases(scenario.observations_patch, basePr, baseUat));
  const opts = { actor: 'driver', lease: null, now: obs.now, config: DEFAULT_CONFIG, ...(scenario.opts || {}) };
  return { snapshot, obs, opts };
}

function loadScenario(file) {
  const scenario = JSON.parse(fs.readFileSync(file, 'utf8'));
  return { ...buildBase(scenario), expected: scenario.expected, name: scenario.name, rule: scenario.rule };
}

function scenarioFiles() {
  return fs.readdirSync(DIR).filter((f) => f.endsWith('.json') && !f.startsWith('_')).sort().map((f) => path.join(DIR, f));
}

module.exports = { DEFAULT_CONFIG, deepMerge, buildBase, loadScenario, scenarioFiles };
