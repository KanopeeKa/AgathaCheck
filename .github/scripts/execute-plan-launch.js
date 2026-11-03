#!/usr/bin/env node
'use strict';

const CURSOR_API_BASE = 'https://api.cursor.com';
const FETCH_TIMEOUT_MS = 30_000;

const TERMINAL_STATUSES = new Set(['FINISHED', 'ERROR', 'CANCELLED', 'EXPIRED']);
const RUNNING_STATUSES = new Set(['CREATING', 'RUNNING']);

const BLANKED_LAUNCH_KEYS = Object.freeze(['OWNER_GH_TOKEN', 'BOT_GH_TOKEN']);

/**
 * Cursor launch envVars for plan workers and issue/dispatch agents.
 * Blanks owner/bot dashboard secrets so workers cannot act as the owner.
 * @param {string} [botToken]
 * @returns {Record<string, string>}
 */
function workerLaunchEnvVars(botToken) {
  const blanked = { OWNER_GH_TOKEN: '', BOT_GH_TOKEN: '' };
  if (botToken && String(botToken).trim()) {
    return {
      GH_TOKEN: botToken,
      EXECUTE_PLAN_TOKEN: botToken,
      ...blanked,
    };
  }
  return blanked;
}

/**
 * Cursor launch envVars for weekly dependabot-batch dispatch only.
 * Passes the bot PAT for default gh identity; does not blank dashboard OWNER_GH_TOKEN so
 * the dispatch prompt's /run-as-me step can export OWNER_GH_TOKEN for merge and PR cleanup.
 * @param {string} [botToken]
 * @returns {Record<string, string>}
 */
function dependabotBatchLaunchEnvVars(botToken) {
  if (botToken && String(botToken).trim()) {
    return {
      GH_TOKEN: botToken,
      EXECUTE_PLAN_TOKEN: botToken,
    };
  }
  return {};
}

/** Cursor API rejects empty envVars values; omit blanks at the HTTP boundary only. */
function envVarsForCursorLaunch(envVars) {
  if (!envVars || typeof envVars !== 'object') return undefined;
  const out = {};
  for (const [key, value] of Object.entries(envVars)) {
    if (value !== '') out[key] = value;
  }
  return Object.keys(out).length > 0 ? out : undefined;
}

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
    signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
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
 * @param {Record<string,string>} [params.envVars] values for the agent's environment, sent in the launch request
 *   (Cursor: take precedence over dashboard secrets). Never logged. Field name/shape unverified against the
 *   official docs (unreachable when written): kept as an object of string -> string.
 * @param {typeof fetch} [params.fetchImpl]
 * @returns {Promise<{ agentId: string, runId: string, agentUrl: string|null }>}
 */
async function launchPlanAgent({
  apiKey,
  repoUrl,
  startingRef,
  prompt,
  model,
  envVars,
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
  const launchEnv = envVarsForCursorLaunch(envVars);
  if (launchEnv) {
    body.envVars = launchEnv;
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
      signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
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
  workerLaunchEnvVars,
  dependabotBatchLaunchEnvVars,
  BLANKED_LAUNCH_KEYS,
  envVarsForCursorLaunch,
};
