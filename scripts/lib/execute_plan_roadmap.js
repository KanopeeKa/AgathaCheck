'use strict';

const { ExecutePlanError } = require('./execute_plan_constants');

const CHILD_STATUS = new Set(['pending', 'in_progress', 'merged', 'skipped']);

function isRoadmap(snapshot) {
  return snapshot.plan_kind === 'roadmap';
}

function validateRoadmap(snapshot) {
  if (!Array.isArray(snapshot.child_plans) || snapshot.child_plans.length === 0) {
    throw new ExecutePlanError('roadmap snapshots require non-empty child_plans[]');
  }
  snapshot.child_plans.forEach((child, index) => {
    if (!child.plan_id || typeof child.plan_id !== 'string') {
      throw new ExecutePlanError(`child_plans[${index}].plan_id required`);
    }
    if (!CHILD_STATUS.has(child.status)) {
      throw new ExecutePlanError(`child_plans[${index}].status invalid`);
    }
  });
  const ids = snapshot.child_plans.map((c) => c.plan_id);
  if (new Set(ids).size !== ids.length) {
    throw new ExecutePlanError('child_plans plan_id values must be unique');
  }
  if (
    snapshot.current_child_plan_id &&
    !ids.includes(snapshot.current_child_plan_id)
  ) {
    throw new ExecutePlanError('current_child_plan_id not found in child_plans');
  }
}

function findNextPendingChild(snapshot) {
  if (!isRoadmap(snapshot)) return null;
  return snapshot.child_plans.find((c) => c.status === 'pending') || null;
}

function findCurrentChild(snapshot) {
  if (!isRoadmap(snapshot) || !snapshot.child_plans) return null;
  if (snapshot.current_child_plan_id) {
    return (
      snapshot.child_plans.find((c) => c.plan_id === snapshot.current_child_plan_id) ||
      null
    );
  }
  return (
    snapshot.child_plans.find((c) => c.status === 'in_progress') ||
    findNextPendingChild(snapshot)
  );
}

function roadmapStatus(snapshot) {
  if (!isRoadmap(snapshot)) {
    throw new ExecutePlanError('roadmap-status requires plan_kind roadmap');
  }
  const pending = snapshot.child_plans.filter((c) => c.status === 'pending');
  const merged = snapshot.child_plans.filter((c) => c.status === 'merged');
  const current = findCurrentChild(snapshot);
  const incomplete = snapshot.child_plans.filter(
    (c) => c.status !== 'merged' && c.status !== 'skipped'
  );
  const complete = incomplete.length === 0 && snapshot.child_plans.length > 0;
  return {
    plan_id: snapshot.plan_id,
    autonomy: snapshot.autonomy,
    current_child_plan_id: current?.plan_id ?? null,
    pending_child_plan_ids: pending.map((c) => c.plan_id),
    merged_child_plan_ids: merged.map((c) => c.plan_id),
    complete,
    next_child_plan_id: pending[0]?.plan_id ?? null,
  };
}

function setRoadmapChildStatus(snapshot, childPlanId, status, fields = {}) {
  if (!isRoadmap(snapshot)) {
    throw new ExecutePlanError('roadmap child updates require plan_kind roadmap');
  }
  if (!CHILD_STATUS.has(status)) {
    throw new ExecutePlanError(`invalid child status: ${status}`);
  }
  const child = snapshot.child_plans.find((c) => c.plan_id === childPlanId);
  if (!child) {
    throw new ExecutePlanError(`unknown child plan_id: ${childPlanId}`);
  }
  child.status = status;
  if (fields.pr_url) child.pr_url = fields.pr_url;
  if (fields.merge_commit) child.merge_commit = fields.merge_commit;

  if (status === 'in_progress') {
    snapshot.current_child_plan_id = childPlanId;
  }
  if (status === 'merged') {
    const next = findNextPendingChild(snapshot);
    snapshot.current_child_plan_id = next ? next.plan_id : null;
  }
  return snapshot;
}

function assertRoadmapCanComplete(snapshot) {
  if (!isRoadmap(snapshot)) return;
  const incomplete = snapshot.child_plans.filter(
    (c) => c.status !== 'merged' && c.status !== 'skipped'
  );
  if (incomplete.length > 0) {
    throw new ExecutePlanError(
      `cannot complete roadmap: child plans not done: ${incomplete.map((c) => c.plan_id).join(', ')}`
    );
  }
}

function computeRoadmapNextAction(snapshot) {
  const status = roadmapStatus(snapshot);
  if (status.complete) return 'roadmap complete';
  if (status.current_child_plan_id) {
    const current = snapshot.child_plans.find(
      (c) => c.plan_id === status.current_child_plan_id
    );
    if (current?.status === 'in_progress') {
      return `continue child plan ${current.plan_id}`;
    }
  }
  if (status.next_child_plan_id) {
    return `bootstrap and gate child plan ${status.next_child_plan_id}`;
  }
  return null;
}

module.exports = {
  CHILD_STATUS,
  isRoadmap,
  validateRoadmap,
  findNextPendingChild,
  findCurrentChild,
  roadmapStatus,
  setRoadmapChildStatus,
  assertRoadmapCanComplete,
  computeRoadmapNextAction,
};
