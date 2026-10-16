'use strict';

/**
 * Execute-plan v2 UAT stage (pure): U-rules of state-machine §4.2, deploy failure classes §4.4.
 * Reads only its arguments; the network observation lives in execute_plan_uat_observe.js and is
 * re-exported here because `tick` looks for `observeUat` on this module (execute_plan_tick.js).
 */

const { observeUat, observeUatChain, parseProofJobLog, resolveMergeSource, watchPreUat, watchDeploy, verifyComplete } = require('./execute_plan_uat_observe');

const DEFAULT_REPO = 'KanopeeKa/AgathaCheck';
const PREUAT_GRACE_MS = 10 * 60 * 1000;
const MAIN_RED_MS = 6 * 60 * 60 * 1000;
const NOT_A_VERDICT = new Set(['cancelled', 'skipped']);

const ms = (iso) => Date.parse(iso);

/** U3: failing jobs are the baseline's own (subset) → not caused by this plan. */
function isAppCaused(candidate, baseline) {
  if (!baseline || baseline.conclusion === 'success') return true;
  const known = new Set(baseline.failed_jobs || []);
  return !(candidate.failed_jobs || []).every((j) => known.has(j));
}

/** State-machine §4.4. @returns {'infra'|'app-smoke'|'unknown'} */
function classifyDeployFailure(run) {
  if (!run) return 'unknown';
  if (run.gate_failure_class === 'infra_only') return 'infra';
  if (run.gate_failure_class === 'code' && run.deploy_job === 'success' && run.smoke_job === 'failure') return 'app-smoke';
  return 'unknown';
}

/** @returns {{ state, phase, action, stop, evidence, budgets }} */
function decideUat(snapshot, obs, ctx) {
  const { finish, wait, driver, agent, applyLeaseRules, prLadder } = ctx;
  const { uat } = obs;
  const { opts } = ctx;
  const status = ctx.status || null;
  const dispatched = (status && status.dispatched) || {};
  const repo = opts.repo || DEFAULT_REPO;
  const runUrl = (label, id) => ({ label, url: `https://github.com/${repo}/actions/runs/${id}` });
  const done = (result, runs = []) => ({ ...result, evidence: [...result.evidence, ...runs.filter((r) => r.id != null).map((r) => runUrl(r.label, r.id))] });
  const out = (state, action, runs) => done(finish(ctx, { state, action }), runs);
  const halt = (reason, detail, runs) => done(finish(ctx, { state: 'stopped', stop: { reason, detail } }), runs);
  const now = ms(opts.now);

  // U1
  if (obs.remedial && obs.remedial.open_pr) {
    const pr = obs.remedial.open_pr;
    return prLadder(pr, {
      ...ctx,
      kind: 'remedial',
      draftAction: { kind: 'remedial', args: { pr: pr.number, branch: pr.head_ref, failing: [], evidence: [] } },
      method: 'squash',
    });
  }

  const budget = snapshot.settings.budgets.remedial_rounds;
  const rounds = (obs.remedial && obs.remedial.merged_since_epoch) || 0;
  const remedial = (failing, runs) => {
    if (rounds >= budget) return halt('preuat-budget', `${rounds} remedial rounds since the epoch (limit ${budget})`, runs);
    const args = { branch: `cursor/${snapshot.plan_id}-remedial-${rounds + 1}`, failing, evidence: runs.filter((r) => r.id != null).map((r) => runUrl(r.label, r.id).url) };
    const r = applyLeaseRules(agent('remedial', args), ctx);
    return done(finish(ctx, { state: 'remedial', action: r.action || null, stop: r.stop || null }), runs);
  };
  const dispatchOrWait = (state, reason, since) => {
    const heads = dispatched.preuat_heads || [];
    if (obs.main.preuat_queued_for_head || now - ms(since) < PREUAT_GRACE_MS) return out(state, wait(reason));
    if (!heads.includes(obs.main.head_sha)) return out(state, driver('dispatch-preuat', { main_head_sha: obs.main.head_sha }));
    return out(state, wait('preuat-dispatched'));
  };

  const runs = uat.preuat_runs || [];
  const C = runs.find((r) => r.contains_merge && r.status === 'completed' && !NOT_A_VERDICT.has(r.conclusion));
  // U2
  if (!C) return dispatchOrWait('awaiting-preuat', 'preuat', uat.merged_at);

  // U3
  if (C.conclusion !== 'success') {
    const evidence = [{ label: 'Pre-UAT run', id: C.id }];
    if (isAppCaused(C, uat.baseline_run)) return remedial(C.failed_jobs || [], evidence);
    if (now - ms(C.updated_at) >= MAIN_RED_MS) return halt('main-red', `Pre-UAT red on main since ${C.updated_at}; baseline is red with the same jobs`, evidence);
    return out('awaiting-main-green', wait('main-green'), evidence);
  }

  // U4
  const tags = (uat.uat_tags || []).filter((t) => t.contains_merge);
  if (!tags.length) return dispatchOrWait('awaiting-promote', 'promote', C.updated_at);

  // U5
  const deploys = uat.deploy_runs || [];
  const D = deploys.find((r) => (r.proof_job === 'success' || r.proof_job === 'failure') && r.deploy_ref_contains_merge === true)
    // a failed proof job whose log has no readable DEPLOY_REF cannot be tied to a tag: §4.4 `unknown`
    || deploys.find((r) => r.proof_job === 'failure' && !r.deploy_ref);
  if (!D) return out('awaiting-deploy', wait('deploy'), [{ label: 'Pre-UAT run', id: C.id }]);
  const evidence = [{ label: 'Pre-UAT run', id: C.id }, { label: 'Deploy UAT run', id: D.id }];

  // U6
  if (D.proof_job === 'success') {
    if (snapshot.settings.tier3_blocking && !(uat.tier3_run && uat.tier3_run.conclusion === 'success')) {
      if (uat.tier3_run && uat.tier3_run.conclusion === 'failure') return halt('tier3-red', `UAT Live E2E run ${uat.tier3_run.id} failed`, evidence);
      return out('awaiting-deploy', wait('tier3'), evidence);
    }
    return out('complete', driver('complete-plan', { evidence: { preuat_run: C.id, tag: D.deploy_ref, deploy_run: D.id } }), evidence);
  }

  // U7: a newer Deploy UAT run (a re-dispatch) that has not finished yet decides first
  if (deploys.some((r) => r.status !== 'completed' && ms(r.created_at) > ms(D.created_at))) return out('awaiting-deploy', wait('deploy'), evidence);
  const cls = classifyDeployFailure(D);
  if (cls === 'infra') {
    if (!(dispatched.deploy_tags || []).includes(D.deploy_ref)) return out('awaiting-deploy', driver('dispatch-deploy', { tag: D.deploy_ref }), evidence);
    return halt('uat-infra', `Deploy UAT failed on infrastructure again for ${D.deploy_ref}`, evidence);
  }
  if (cls === 'app-smoke') return remedial(['deploy-smoke'], evidence);
  return halt('uat-unknown', `Deploy UAT run ${D.id} failed with an unclassified cause (gate_failure_class=${D.gate_failure_class})`, evidence);
}

module.exports = {
  decideUat, classifyDeployFailure, isAppCaused,
  observeUat, observeUatChain, parseProofJobLog, resolveMergeSource, watchPreUat, watchDeploy, verifyComplete,
};
