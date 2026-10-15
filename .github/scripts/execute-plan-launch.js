#!/usr/bin/env node
'use strict';

const CURSOR_API_BASE = 'https://api.cursor.com';

const TERMINAL_STATUSES = new Set(['FINISHED', 'ERROR', 'CANCELLED', 'EXPIRED']);
const RUNNING_STATUSES = new Set(['CREATING', 'RUNNING']);

/**
 * @param {typeof fetch} fetchImpl
 */
function resolveFetch(fetchImpl) {
  return fetchImpl || globalThis.fetch;
}

/**
 * @param {typeof fetch} fetchImpl
 * @param {string} method
 * @param {string} path
 * @param {string} apiKey
 * @param {object} [body]
 */
async function cursorApi(fetchImpl, method, path, apiKey, body) {
  const response = await fetchImpl(`${CURSOR_API_BASE}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: body ? JSON.stringify(body) : undefined,
  });

  const text = await response.text();
  let payload;
  try {
    payload = text ? JSON.parse(text) : {};
  } catch {
    payload = { raw: text };
  }

  if (!response.ok) {
    throw new Error(
      `Cursor API ${method} ${path} failed (${response.status}): ${JSON.stringify(payload)}`,
    );
  }
  return payload;
}

/**
 * @param {object} params
 * @param {string} params.apiKey
 * @param {string} params.repoUrl
 * @param {string} params.startingRef
 * @param {string} params.prompt
 * @param {string} [params.model]
 * @param {typeof fetch} [params.fetchImpl]
 * @returns {Promise<{ agentId: string, runId: string, agentUrl: string|null }>}
 */
async function launchPlanAgent({
  apiKey,
  repoUrl,
  startingRef,
  prompt,
  model,
  fetchImpl,
}) {
  const fetchFn = resolveFetch(fetchImpl);

  const body = {
    prompt: { text: prompt },
    repos: [{ url: repoUrl, startingRef }],
    autoCreatePR: false,
    workOnCurrentBranch: true,
  };

  if (model) {
    body.model = { id: model };
  }

  const launched = await cursorApi(fetchFn, 'POST', '/v1/agents', apiKey, body);

  const agentId = launched.agent?.id;
  const runId = launched.run?.id;
  const agentUrl = launched.agent?.url ?? null;

  if (!agentId || !runId) {
    throw new Error(`Cursor API response missing agent/run id: ${JSON.stringify(launched)}`);
  }

  return { agentId, runId, agentUrl };
}

/**
 * @param {object} params
 * @param {string} params.apiKey
 * @param {string} params.agentId
 * @param {string} params.runId
 * @param {typeof fetch} [params.fetchImpl]
 * @returns {Promise<'CREATING'|'RUNNING'|'FINISHED'|'ERROR'|'CANCELLED'|'EXPIRED'|'UNKNOWN'>}
 */
async function getAgentRunStatus({ apiKey, agentId, runId, fetchImpl }) {
  const fetchFn = resolveFetch(fetchImpl);
  const path = `/v1/agents/${agentId}/runs/${runId}`;

  try {
    const response = await fetchFn(`${CURSOR_API_BASE}${path}`, {
      headers: { Authorization: `Bearer ${apiKey}` },
    });
    const text = await response.text();
    if (!response.ok) {
      return 'UNKNOWN';
    }
    const run = text ? JSON.parse(text) : {};
    const status = run.status;
    if (
      RUNNING_STATUSES.has(status) ||
      TERMINAL_STATUSES.has(status)
    ) {
      return status;
    }
    return 'UNKNOWN';
  } catch {
    return 'UNKNOWN';
  }
}

module.exports = {
  launchPlanAgent,
  getAgentRunStatus,
  CURSOR_API_BASE,
};
