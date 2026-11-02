#!/usr/bin/env node
'use strict';

/**
 * WP11 owner probe: launch a read-only Cloud agent with workerLaunchEnvVars and classify its env report.
 * Requires CURSOR_API_KEY (Actions automation secret). Never logs token values or raw agent text.
 */

const {
  launchPlanAgent,
  getAgentRunStatus,
  CURSOR_API_BASE,
  workerLaunchEnvVars,
} = require('./execute-plan-launch');

const REPO_URL = 'https://github.com/KanopeeKa/AgathaCheck';
const POLL_MS = 15_000;
const TIMEOUT_MS = 12 * 60 * 1000;

const PROMPT = [
  'Probe only. Do not change any file, do not commit, do not open a pull request.',
  'Run this exact command once and reply with its output, nothing else:',
  'for v in OWNER_GH_TOKEN BOT_GH_TOKEN GH_TOKEN EXECUTE_PLAN_TOKEN; do if [ -n "${!v}" ]; then echo "$v present"; else echo "$v absent"; fi; done; echo "injected: $CLOUD_AGENT_INJECTED_SECRET_NAMES"',
].join('\n');

async function fetchRun(apiKey, agentId, runId) {
  const response = await fetch(`${CURSOR_API_BASE}/v1/agents/${agentId}/runs/${runId}`, {
    headers: { Authorization: `Bearer ${apiKey}` },
    signal: AbortSignal.timeout(30_000),
  });
  const text = await response.text();
  if (!response.ok) {
    throw new Error(`Cursor run GET failed (${response.status})`);
  }
  return text ? JSON.parse(text) : {};
}

function classifyProbeOutput(text) {
  const raw = String(text || '');
  const status = (name) => {
    if (new RegExp(`${name} present`).test(raw)) return 'present';
    if (new RegExp(`${name} absent`).test(raw)) return 'absent';
    return undefined;
  };
  const map = {
    OWNER_GH_TOKEN: status('OWNER_GH_TOKEN'),
    BOT_GH_TOKEN: status('BOT_GH_TOKEN'),
    GH_TOKEN: status('GH_TOKEN'),
    EXECUTE_PLAN_TOKEN: status('EXECUTE_PLAN_TOKEN'),
  };
  const pass =
    map.OWNER_GH_TOKEN === 'absent' &&
    map.BOT_GH_TOKEN === 'absent' &&
    map.GH_TOKEN === 'present' &&
    map.EXECUTE_PLAN_TOKEN === 'present';
  const failOwner = map.OWNER_GH_TOKEN === 'present';
  return { map, pass, failOwner, replyLength: raw.trim().length };
}

async function main() {
  const apiKey = process.env.CURSOR_API_KEY || process.env.cursor_api_key;
  if (!apiKey || !String(apiKey).trim()) {
    console.error('CURSOR_API_KEY is required');
    process.exit(1);
  }

  const launched = await launchPlanAgent({
    apiKey,
    repoUrl: REPO_URL,
    startingRef: 'main',
    prompt: PROMPT,
    model: 'composer-2.5',
    envVars: workerLaunchEnvVars('probe-not-a-token'),
  }).catch((e) => {
    if (/envVars value cannot be empty/i.test(String(e.message))) {
      console.log('WP11_PROBE_LAUNCH=API_REJECTS_EMPTY_ENVVARS');
    }
    throw e;
  });

  console.log(`probe_agent_id=${launched.agentId}`);
  console.log(`probe_run_id=${launched.runId}`);
  if (launched.agentUrl) console.log(`probe_url=${launched.agentUrl}`);

  const deadline = Date.now() + TIMEOUT_MS;
  let lastStatus = 'UNKNOWN';
  while (Date.now() < deadline) {
    lastStatus = await getAgentRunStatus({
      apiKey,
      agentId: launched.agentId,
      runId: launched.runId,
    });
    if (lastStatus === 'FINISHED') break;
    if (['ERROR', 'CANCELLED', 'EXPIRED'].includes(lastStatus)) {
      console.error(`probe run ended: ${lastStatus}`);
      process.exit(2);
    }
    await new Promise((r) => setTimeout(r, POLL_MS));
  }
  if (lastStatus !== 'FINISHED') {
    console.error('probe timed out waiting for agent');
    process.exit(2);
  }

  const run = await fetchRun(apiKey, launched.agentId, launched.runId);
  const reply = run.result?.text || run.text || '';
  const { pass, failOwner, map, replyLength } = classifyProbeOutput(reply);
  console.log(`probe_reply_length=${replyLength}`);
  console.log('--- classification ---');
  console.log(JSON.stringify({ ...map, pass, failOwner }, null, 2));

  if (pass) {
    console.log('WP11_PROBE=PASS');
    process.exit(0);
  }
  if (failOwner) {
    console.log('WP11_PROBE=FAIL_OWNER_PRESENT');
    process.exit(3);
  }
  console.log('WP11_PROBE=INCONCLUSIVE');
  process.exit(4);
}

main().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
