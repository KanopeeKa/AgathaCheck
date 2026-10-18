'use strict';

/**
 * Execute-plan v2 UAT observation (state-machine §4.0 `UatObservations`), watchers and
 * `verifyComplete` (Definition of Done, index §1). Reads only; "contains" is always
 * `compare(merge_sha...candidate).status ∈ {ahead, identical}`, never SHA equality (B2).
 */

const CONTAINS = new Set(['ahead', 'identical']);
const PREUAT_MAX = 20;
const DEPLOY_MAX = 10;
const BASELINE_PROBES = 10;
const NOT_A_VERDICT = new Set(['cancelled', 'skipped']);

const ms = (iso) => Date.parse(iso);
const byNewest = (a, b) => ms(b.created_at) - ms(a.created_at);
const sleepMs = (t) => new Promise((r) => setTimeout(r, t));
const utcYymmdd = (iso) => new Date(ms(iso)).toISOString().slice(2, 10).replace(/-/g, '');
const missingRef = (e) => e && (e.status === 404 || e.status === 422);

/** Formats verified on the `Prod ready` job log of run 38587026601. */
function parseProofJobLog(text) {
  const s = String(text == null ? '' : text);
  const ref = /DEPLOY_REF:\s*(uat-\d{6}-\d+)/.exec(s);
  const cls = /gate_failure_class=(none|infra_only|code)/.exec(s);
  return { deploy_ref: ref ? ref[1] : null, gate_failure_class: cls ? cls[1] : null };
}

/** Compare with a per-observation cache; an unknown ref is "does not contain". */
function containsFn(client, mergeSha) {
  const cache = new Map();
  return async (candidate) => {
    if (!candidate) return false;
    if (!cache.has(candidate)) {
      cache.set(candidate, client.compare(mergeSha, candidate).then((c) => CONTAINS.has(c.status)).catch((e) => {
        if (missingRef(e)) return false;
        throw e;
      }));
    }
    return cache.get(candidate);
  };
}

/** The most recently merged plan PR into main: the release PR, or a later remedial PR. */
async function resolveMergeSource(client, snapshot, { releasePr } = {}) {
  const intoMain = await client.listPulls({ base: 'main', state: 'all', pages: 3 });
  const prefix = `cursor/${snapshot.plan_id}-remedial-`;
  const cands = intoMain
    .filter((p) => p.merged_at && p.merge_commit_sha && (p.head.ref === snapshot.integration_branch || p.head.ref.startsWith(prefix)))
    .map((p) => ({ number: p.number, kind: p.head.ref === snapshot.integration_branch ? 'release' : 'remedial', merged_at: p.merged_at, sha: p.merge_commit_sha }));
  if (releasePr && releasePr.merged_at && releasePr.merge_commit_sha && !cands.some((c) => c.number === releasePr.number)) {
    cands.push({ number: releasePr.number, kind: 'release', merged_at: releasePr.merged_at, sha: releasePr.merge_commit_sha });
  }
  const release = cands.filter((c) => c.kind === 'release').sort((a, b) => ms(b.merged_at) - ms(a.merged_at))[0];
  if (!release) return null;
  const latest = cands.filter((c) => c.kind === 'remedial' && ms(c.merged_at) > ms(release.merged_at))
    .sort((a, b) => ms(b.merged_at) - ms(a.merged_at))[0] || release;
  return { mergeSha: latest.sha, mergedAt: latest.merged_at, source: { kind: latest.kind, pr: latest.number } };
}

async function failedJobs(client, run, gateJob) {
  if (run.conclusion !== 'failure') return [];
  const jobs = await client.listRunJobs(run.id);
  return jobs.filter((j) => j.conclusion === 'failure' && j.name !== gateJob).map((j) => j.name).sort();
}

const preuatShape = (run, contains, failed) => ({
  id: run.id, head_sha: run.head_sha, event: run.event, status: run.status, conclusion: run.conclusion || null,
  created_at: run.created_at, updated_at: run.updated_at, contains_merge: contains, failed_jobs: failed,
});

async function observePreUat(client, { mergeSha, mergedAt, config, contains }) {
  const all = (await client.listWorkflowRuns(config.uat.preuat_workflow, { branch: 'main', pages: 1 })).sort(byNewest);
  const gate = config.uat.preuat_gate_job;
  const after = all.filter((r) => !mergedAt || ms(r.created_at) >= ms(mergedAt)).slice(0, PREUAT_MAX);
  const preuat_runs = [];
  for (const r of after) preuat_runs.push(preuatShape(r, await contains(r.head_sha), await failedJobs(client, r, gate)));

  let baseline_run = null;
  const older = all.filter((r) => r.status === 'completed' && !NOT_A_VERDICT.has(r.conclusion) && r.head_sha !== mergeSha).slice(0, BASELINE_PROBES);
  for (const r of older) {
    const rel = await client.compare(r.head_sha, mergeSha).catch((e) => { if (missingRef(e)) return null; throw e; });
    if (rel && rel.status === 'ahead') { baseline_run = preuatShape(r, false, await failedJobs(client, r, gate)); break; }
  }
  return { preuat_runs, baseline_run };
}

async function observeTags(client, { mergedAt, config, contains }) {
  const pattern = new RegExp(config.uat.tag_pattern);
  const since = mergedAt ? utcYymmdd(mergedAt) : null;
  const tags = (await client.listTags({ pages: 3 })).filter((t) => {
    const m = pattern.exec(t.name);
    return m && (!since || m[1] >= since);
  });
  const out = [];
  for (const t of tags) out.push({ name: t.name, commit_sha: t.commit.sha, contains_merge: await contains(t.commit.sha) });
  return out;
}

async function logOrNull(client, jobId) {
  try {
    return await client.getJobLog(jobId);
  } catch (e) {
    if (e && (e.status === 404 || e.status === 410)) return null; // expired logs
    throw e;
  }
}

async function observeDeploys(client, { mergedAt, config, tags, contains }) {
  const u = config.uat;
  const runs = (await client.listWorkflowRuns(u.deploy_workflow, { pages: 1 })).sort(byNewest)
    .filter((r) => !mergedAt || ms(r.created_at) >= ms(mergedAt)).slice(0, DEPLOY_MAX);
  const out = [];
  for (const r of runs) {
    const jobs = await client.listRunJobs(r.id);
    const state = (name) => {
      const j = jobs.find((x) => x.name === name);
      return j ? (j.conclusion || (j.status === 'completed' ? null : 'pending')) : 'missing';
    };
    const shape = {
      id: r.id, created_at: r.created_at, status: r.status, conclusion: r.conclusion || null,
      proof_job: state(u.deploy_proof_job), deploy_job: state(u.deploy_job), smoke_job: state(u.smoke_job),
      deploy_ref: null, deploy_ref_contains_merge: false, gate_failure_class: null,
    };
    if (shape.proof_job === 'success' || shape.proof_job === 'failure') {
      const log = await logOrNull(client, jobs.find((x) => x.name === u.deploy_proof_job).id);
      Object.assign(shape, parseProofJobLog(log));
      const known = tags.find((t) => t.name === shape.deploy_ref);
      shape.deploy_ref_contains_merge = known ? known.contains_merge : await contains(shape.deploy_ref);
    }
    out.push(shape);
  }
  return out;
}

/** @returns {Promise<object>} UatObservations for one merge (state-machine §4.0). */
async function observeUatChain(client, { mergeSha, mergedAt = null, source = null, config }) {
  const contains = containsFn(client, mergeSha);
  const { preuat_runs, baseline_run } = await observePreUat(client, { mergeSha, mergedAt, config, contains });
  const uat_tags = await observeTags(client, { mergedAt, config, contains });
  const deploy_runs = await observeDeploys(client, { mergedAt, config, tags: uat_tags, contains });
  const qualifying = deploy_runs.find((r) => r.proof_job === 'success' && r.deploy_ref_contains_merge);
  let tier3_run = null;
  if (qualifying) {
    const runs = (await client.listWorkflowRuns(config.uat.tier3_workflow, { pages: 1 })).sort(byNewest)
      .filter((r) => ms(r.created_at) > ms(qualifying.created_at));
    if (runs[0]) tier3_run = { id: runs[0].id, status: runs[0].status, conclusion: runs[0].conclusion || null };
  }
  return { merge_sha: mergeSha, merged_at: mergedAt, source, preuat_runs, baseline_run, uat_tags, deploy_runs, tier3_run };
}

/**
 * The call shape `tick` uses: `observeUat(client, ctx, obs, { now })`.
 * @returns {Promise<object|null>} null when no plan PR into main has merged
 */
async function observeUat(client, ctx, obs) {
  const found = await resolveMergeSource(client, ctx.snapshot, { releasePr: obs && obs.release && obs.release.pr });
  if (!found) return null;
  return observeUatChain(client, { ...found, config: ctx.config });
}

async function configFrom(client, opts) {
  if (opts.config) return opts.config;
  const file = await client.getFileAtRef('.github/execute-plan.config.json', 'main');
  if (!file) throw new Error('.github/execute-plan.config.json not found on main');
  return JSON.parse(file.content);
}

async function poll(check, { timeoutMin, pollSec, sleep }) {
  const polls = Math.max(1, Math.ceil((timeoutMin * 60) / pollSec));
  let latest = null;
  for (let i = 0; i < polls; i += 1) {
    latest = await check();
    if (latest.done) return { timedOut: false, ...latest.value };
    if (i < polls - 1) await sleep(pollSec * 1000);
  }
  return { timedOut: true, ...latest.value };
}

/** Waits for a Pre-UAT run on main whose head contains `mergeSha` and that completed with a verdict. */
async function watchPreUat(client, { mergeSha, mergedAt = null, config, timeoutMin = 90, pollSec = 120, sleep = sleepMs }) {
  const cfg = await configFrom(client, { config });
  return poll(async () => {
    const { preuat_runs } = await observePreUat(client, { mergeSha, mergedAt, config: cfg, contains: containsFn(client, mergeSha) });
    const run = preuat_runs.find((r) => r.contains_merge && r.status === 'completed' && !NOT_A_VERDICT.has(r.conclusion)) || null;
    return { done: Boolean(run), value: { run: run && { id: run.id, head_sha: run.head_sha, conclusion: run.conclusion, failed_jobs: run.failed_jobs } } };
  }, { timeoutMin, pollSec, sleep });
}

/** Waits for a Deploy UAT run whose `Prod ready` job finished (not skipped) on a tag containing `mergeSha`. */
async function watchDeploy(client, { mergeSha, mergedAt = null, config, timeoutMin = 45, pollSec = 120, sleep = sleepMs }) {
  const cfg = await configFrom(client, { config });
  return poll(async () => {
    const chain = await observeUatChain(client, { mergeSha, mergedAt, config: cfg });
    const run = chain.deploy_runs.find((r) => (r.proof_job === 'success' || r.proof_job === 'failure') && r.deploy_ref_contains_merge) || null;
    return { done: Boolean(run), value: { run: run && { id: run.id, proof_job: run.proof_job, deploy_ref: run.deploy_ref, gate_failure_class: run.gate_failure_class } } };
  }, { timeoutMin, pollSec, sleep });
}

/**
 * Re-observes GitHub and answers the Definition of Done (index §1). ctx = { snapshot, config }.
 * @returns {Promise<{ complete: boolean, missing: string|null, evidence: object }>}
 */
async function verifyComplete(client, ctx) {
  const found = await resolveMergeSource(client, ctx.snapshot);
  if (!found) return { complete: false, missing: 'release-merged', evidence: {} };
  const chain = await observeUatChain(client, { ...found, config: ctx.config });
  const preuat = chain.preuat_runs.find((r) => r.contains_merge && r.status === 'completed' && r.conclusion === 'success');
  const tag = chain.uat_tags.find((t) => t.contains_merge);
  const deploy = chain.deploy_runs.find((r) => r.proof_job === 'success' && r.deploy_ref_contains_merge);
  const evidence = {
    merge_sha: found.mergeSha, source: found.source,
    preuat_run: preuat ? preuat.id : null, tag: tag ? tag.name : null,
    deploy_run: deploy ? deploy.id : null, deploy_ref: deploy ? deploy.deploy_ref : null,
    tier3_run: chain.tier3_run,
  };
  let missing = null;
  if (!preuat) missing = 'preuat-success';
  else if (!tag) missing = 'uat-tag';
  else if (!deploy) missing = 'deploy-proof';
  else if (ctx.snapshot.settings.tier3_blocking && !(chain.tier3_run && chain.tier3_run.conclusion === 'success')) missing = 'tier3';
  return { complete: missing === null, missing, evidence };
}

module.exports = { observeUat, observeUatChain, parseProofJobLog, resolveMergeSource, watchPreUat, watchDeploy, verifyComplete };
