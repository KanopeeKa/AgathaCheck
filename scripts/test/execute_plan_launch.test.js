#!/usr/bin/env node
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  launchPlanAgent,
  getAgentRunStatus,
  CURSOR_API_BASE,
} = require('../../.github/scripts/execute-plan-launch');

const API_KEY = 'test-api-key';
const REPO_URL = 'https://github.com/org/repo';
const STARTING_REF = 'cursor/plan-p1-abc1';

function fakeFetch(handlers) {
  return async (url, options = {}) => {
    const path = url.replace(CURSOR_API_BASE, '');
    const handler = handlers[path];
    if (!handler) {
      throw new Error(`Unexpected fetch: ${url}`);
    }
    return handler(path, options);
  };
}

test('launch request body matches the contract', async () => {
  let capturedBody;
  const fetchImpl = fakeFetch({
    '/v1/agents': async (_path, options) => {
      capturedBody = JSON.parse(options.body);
      return {
        ok: true,
        text: async () =>
          JSON.stringify({
            agent: { id: 'bc-agent-1', url: 'https://cursor.com/agents/bc-agent-1' },
            run: { id: 'run-1' },
          }),
      };
    },
  });

  await launchPlanAgent({
    apiKey: API_KEY,
    repoUrl: REPO_URL,
    startingRef: STARTING_REF,
    prompt: 'Implement phase 1',
    model: 'composer-2.5',
    fetchImpl,
  });

  assert.equal(capturedBody.prompt.text, 'Implement phase 1');
  assert.deepEqual(capturedBody.repos, [{ url: REPO_URL, startingRef: STARTING_REF }]);
  assert.equal(capturedBody.autoCreatePR, false);
  assert.equal(capturedBody.workOnCurrentBranch, true);
  assert.deepEqual(capturedBody.model, { id: 'composer-2.5' });
});

test('launch omits model when not provided', async () => {
  let capturedBody;
  const fetchImpl = fakeFetch({
    '/v1/agents': async (_path, options) => {
      capturedBody = JSON.parse(options.body);
      return {
        ok: true,
        text: async () =>
          JSON.stringify({
            agent: { id: 'bc-agent-2' },
            run: { id: 'run-2' },
          }),
      };
    },
  });

  await launchPlanAgent({
    apiKey: API_KEY,
    repoUrl: REPO_URL,
    startingRef: STARTING_REF,
    prompt: 'Fix CI',
    fetchImpl,
  });

  assert.equal(capturedBody.model, undefined);
});

test('launch returns ids from the response', async () => {
  const fetchImpl = fakeFetch({
    '/v1/agents': async () => ({
      ok: true,
      text: async () =>
        JSON.stringify({
          agent: { id: 'bc-agent-3', url: 'https://cursor.com/agents/bc-agent-3' },
          run: { id: 'run-3' },
        }),
    }),
  });

  const result = await launchPlanAgent({
    apiKey: API_KEY,
    repoUrl: REPO_URL,
    startingRef: STARTING_REF,
    prompt: 'Work',
    fetchImpl,
  });

  assert.deepEqual(result, {
    agentId: 'bc-agent-3',
    runId: 'run-3',
    agentUrl: 'https://cursor.com/agents/bc-agent-3',
  });
});

test('launch throws when agent or run id is missing', async () => {
  const fetchImpl = fakeFetch({
    '/v1/agents': async () => ({
      ok: true,
      text: async () => JSON.stringify({ agent: { id: 'bc-only' } }),
    }),
  });

  await assert.rejects(
    () =>
      launchPlanAgent({
        apiKey: API_KEY,
        repoUrl: REPO_URL,
        startingRef: STARTING_REF,
        prompt: 'Work',
        fetchImpl,
      }),
    /missing agent\/run id/,
  );
});

test('status maps RUNNING', async () => {
  const fetchImpl = fakeFetch({
    '/v1/agents/bc-a/runs/run-b': async () => ({
      ok: true,
      text: async () => JSON.stringify({ status: 'RUNNING' }),
    }),
  });

  const status = await getAgentRunStatus({
    apiKey: API_KEY,
    agentId: 'bc-a',
    runId: 'run-b',
    fetchImpl,
  });

  assert.equal(status, 'RUNNING');
});

test('status maps CREATING and terminal statuses', async () => {
  for (const expected of ['CREATING', 'FINISHED', 'ERROR', 'CANCELLED', 'EXPIRED']) {
    const fetchImpl = fakeFetch({
      '/v1/agents/bc-x/runs/run-y': async () => ({
        ok: true,
        text: async () => JSON.stringify({ status: expected }),
      }),
    });
    const status = await getAgentRunStatus({
      apiKey: API_KEY,
      agentId: 'bc-x',
      runId: 'run-y',
      fetchImpl,
    });
    assert.equal(status, expected);
  }
});

test('status error → UNKNOWN', async () => {
  const fetchImpl = fakeFetch({
    '/v1/agents/bc-a/runs/run-b': async () => ({
      ok: false,
      text: async () => 'not found',
    }),
  });

  const status = await getAgentRunStatus({
    apiKey: API_KEY,
    agentId: 'bc-a',
    runId: 'run-b',
    fetchImpl,
  });

  assert.equal(status, 'UNKNOWN');
});

test('status network failure → UNKNOWN', async () => {
  const fetchImpl = async () => {
    throw new Error('network down');
  };

  const status = await getAgentRunStatus({
    apiKey: API_KEY,
    agentId: 'bc-a',
    runId: 'run-b',
    fetchImpl,
  });

  assert.equal(status, 'UNKNOWN');
});

test('status unknown value → UNKNOWN', async () => {
  const fetchImpl = fakeFetch({
    '/v1/agents/bc-a/runs/run-b': async () => ({
      ok: true,
      text: async () => JSON.stringify({ status: 'PENDING' }),
    }),
  });

  const status = await getAgentRunStatus({
    apiKey: API_KEY,
    agentId: 'bc-a',
    runId: 'run-b',
    fetchImpl,
  });

  assert.equal(status, 'UNKNOWN');
});
