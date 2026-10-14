#!/usr/bin/env node
'use strict';

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');

const {
  buildDependabotBatchPayload,
  buildDependabotBatchPrompt,
  REQUIRED_MODEL,
  SKILL_PATH,
} = require('./dependabot_batch_payload');

describe('dependabot_batch_payload', () => {
  it('builds payload with no CI gate and composer-2.5 model', () => {
    const payload = buildDependabotBatchPayload({
      repository: 'https://github.com/org/repo',
      dispatchedAt: '2026-10-14T10:00:00.000Z',
      trigger: 'schedule',
    });

    assert.equal(payload.task, 'dependabot-batch');
    assert.equal(payload.skill, SKILL_PATH);
    assert.equal(payload.policy.ci_gate_before_dispatch, false);
    assert.equal(payload.constraints.model, REQUIRED_MODEL);
    assert.equal(payload.constraints.suggestedBranch, 'cursor/deps-batch-2026-10-14-6409');
  });

  it('prompt references skill and drop/include classification', () => {
    const payload = buildDependabotBatchPayload({
      repository: 'https://github.com/org/repo',
      dispatchedAt: '2026-10-14T10:00:00.000Z',
    });
    const prompt = buildDependabotBatchPrompt(payload);

    assert.match(prompt, /dependabot-batch\/SKILL\.md/);
    assert.match(prompt, /Drop \/ Include \/ Defer/);
    assert.match(prompt, /No pre-dispatch CI gate/);
  });
});
