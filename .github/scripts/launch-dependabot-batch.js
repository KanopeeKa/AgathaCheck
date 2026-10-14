#!/usr/bin/env node
'use strict';

const { launchAgent } = require('./launch-cursor-agent');
const { parseRepo } = require('./github-project-lib');
const {
  buildDependabotBatchPayload,
  buildDependabotBatchPrompt,
  REQUIRED_MODEL,
} = require('../../scripts/lib/dependabot_batch_payload');

async function launchDependabotBatch({
  repository,
  apiKey,
  dryRun = false,
  trigger = 'schedule',
}) {
  const { owner, repo } = parseRepo(repository);
  const repoUrl = `https://github.com/${owner}/${repo}`;
  const payload = buildDependabotBatchPayload({
    repository: repoUrl,
    trigger,
  });
  const promptText = buildDependabotBatchPrompt(payload);

  console.log('Dependabot batch payload:');
  console.log(JSON.stringify(payload, null, 2));

  if (dryRun) {
    console.log('DRY_RUN=true — skipping Cursor API call.');
    return { dry_run: true, payload };
  }

  if (!apiKey) {
    throw new Error(
      'cursor_api_key secret is required (Cursor dashboard key name: github-actions-pawpet-automation)',
    );
  }

  const model = process.env.CURSOR_AGENT_MODEL || REQUIRED_MODEL;
  const launched = await launchAgent({
    apiKey,
    repoUrl,
    promptText,
    model,
  });

  const agentId = launched.agent?.id;
  const runId = launched.run?.id;
  const agentUrl = launched.agent?.url;
  if (!agentId || !runId) {
    throw new Error(`Cursor API response missing agent/run id: ${JSON.stringify(launched)}`);
  }

  const marker = {
    agentId,
    runId,
    status: 'running',
    dispatchedAt: payload.dispatched_at,
    agentUrl,
    task: 'dependabot-batch',
  };

  return { launched: marker, payload };
}

async function main() {
  const repository = process.env.GITHUB_REPOSITORY;
  const apiKey = process.env.cursor_api_key || process.env.CURSOR_API_KEY;
  const dryRun = process.env.DRY_RUN === 'true';
  const trigger = process.env.DISPATCH_TRIGGER || 'schedule';

  if (!repository) {
    throw new Error('GITHUB_REPOSITORY is required');
  }

  const result = await launchDependabotBatch({
    repository,
    apiKey,
    dryRun,
    trigger,
  });

  console.log(JSON.stringify(result, null, 2));

  const summaryPath = process.env.GITHUB_STEP_SUMMARY;
  if (summaryPath && result.launched) {
    const { launched } = result;
    const body = [
      '## Dependabot batch agent dispatched',
      '',
      `- Agent: ${launched.agentUrl || launched.agentId}`,
      `- Agent id: \`${launched.agentId}\``,
      `- Run id: \`${launched.runId}\``,
      `- Dispatched: ${launched.dispatchedAt}`,
      '',
    ].join('\n');
    const fs = require('fs');
    fs.appendFileSync(summaryPath, body);
  }
}

if (require.main === module) {
  main().catch((error) => {
    console.error(error);
    process.exit(1);
  });
}

module.exports = {
  launchDependabotBatch,
  REQUIRED_MODEL,
};
