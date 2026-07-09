#!/usr/bin/env node
'use strict';

const { evaluateIssue, buildComment } = require('./triage-lib');

const REQUIRED_ENVS = ['GITHUB_TOKEN', 'GITHUB_REPOSITORY', 'ISSUE_NUMBER'];

async function graphql(token, query, variables = {}) {
  const response = await fetch('https://api.github.com/graphql', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ query, variables }),
  });

  const payload = await response.json();
  if (!response.ok || payload.errors) {
    throw new Error(
      `GraphQL request failed: ${JSON.stringify(payload.errors || payload, null, 2)}`,
    );
  }
  return payload.data;
}

async function rest(method, path, token, body) {
  const response = await fetch(`https://api.github.com${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
      ...(body ? { 'Content-Type': 'application/json' } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`GitHub REST ${method} ${path} failed (${response.status}): ${text}`);
  }

  if (response.status === 204) return null;
  return response.json();
}

async function fetchIssue(owner, repo, issueNumber, token) {
  const data = await graphql(
    token,
    `query($owner: String!, $repo: String!, $number: Int!) {
      repository(owner: $owner, name: $repo) {
        issue(number: $number) {
          id
          number
          title
          body
          labels(first: 50) { nodes { name } }
          projectItems(first: 20) {
            nodes {
              id
              project { id }
            }
          }
        }
      }
    }`,
    { owner, repo, number: Number(issueNumber) },
  );

  const issue = data.repository?.issue;
  if (!issue) {
    throw new Error(`Issue #${issueNumber} not found in ${owner}/${repo}`);
  }
  return issue;
}

async function getStatusOptionId(projectsPat, statusFieldId, statusName) {
  const data = await graphql(
    projectsPat,
    `query($fieldId: ID!) {
      node(id: $fieldId) {
        ... on ProjectV2SingleSelectField {
          options { id name }
        }
      }
    }`,
    { fieldId: statusFieldId },
  );

  const options = data.node?.options || [];
  const match = options.find(
    (option) => option.name.toLowerCase() === statusName.toLowerCase(),
  );
  if (!match) {
    throw new Error(
      `Status option "${statusName}" not found on field ${statusFieldId}. Available: ${options
        .map((o) => o.name)
        .join(', ')}`,
    );
  }
  return match.id;
}

async function ensureProjectItem(issue, projectId, projectsPat) {
  const existing = issue.projectItems.nodes.find((item) => item.project.id === projectId);
  if (existing) return existing.id;

  const data = await graphql(
    projectsPat,
    `mutation($projectId: ID!, $contentId: ID!) {
      addProjectV2ItemById(input: { projectId: $projectId, contentId: $contentId }) {
        item { id }
      }
    }`,
    { projectId, contentId: issue.id },
  );

  return data.addProjectV2ItemById.item.id;
}

async function updateProjectStatus({
  issue,
  projectId,
  statusFieldId,
  statusName,
  projectsPat,
}) {
  const itemId = await ensureProjectItem(issue, projectId, projectsPat);
  const optionId = await getStatusOptionId(projectsPat, statusFieldId, statusName);

  await graphql(
    projectsPat,
    `mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
      updateProjectV2ItemFieldValue(
        input: {
          projectId: $projectId
          itemId: $itemId
          fieldId: $fieldId
          value: { singleSelectOptionId: $optionId }
        }
      ) {
        projectV2Item { id }
      }
    }`,
    {
      projectId,
      itemId,
      fieldId: statusFieldId,
      optionId,
    },
  );
}

async function upsertTriageComment(owner, repo, issueNumber, body, token) {
  const comments = await rest(
    'GET',
    `/repos/${owner}/${repo}/issues/${issueNumber}/comments`,
    token,
  );
  const marker = '<!-- triage-human-reviewed -->';
  const existing = comments.find((comment) => comment.body?.includes(marker));

  if (existing) {
    await rest(
      'PATCH',
      `/repos/${owner}/${repo}/issues/comments/${existing.id}`,
      token,
      { body },
    );
    return;
  }

  await rest('POST', `/repos/${owner}/${repo}/issues/${issueNumber}/comments`, token, {
    body,
  });
}

async function setLabels(owner, repo, issueNumber, add, remove, token) {
  if (remove.length > 0) {
    for (const label of remove) {
      await rest(
        'DELETE',
        `/repos/${owner}/${repo}/issues/${issueNumber}/labels/${encodeURIComponent(label)}`,
        token,
      ).catch(() => {});
    }
  }

  if (add.length > 0) {
    await rest('POST', `/repos/${owner}/${repo}/issues/${issueNumber}/labels`, token, {
      labels: add,
    });
  }
}

async function main() {
  for (const key of REQUIRED_ENVS) {
    if (!process.env[key]) {
      throw new Error(`Missing required environment variable: ${key}`);
    }
  }

  const [owner, repo] = process.env.GITHUB_REPOSITORY.split('/');
  const issueNumber = process.env.ISSUE_NUMBER;
  const token = process.env.GITHUB_TOKEN;
  const projectsPat = process.env.GH_PROJECTS_PAT;
  const projectId = process.env.GH_PROJECT_ID;
  const statusFieldId = process.env.GH_STATUS_FIELD_ID;

  const issue = await fetchIssue(owner, repo, issueNumber, token);
  const labels = issue.labels.nodes.map((node) => node.name);

  const result = evaluateIssue({
    title: issue.title,
    body: issue.body || '',
    labels,
  });

  console.log(JSON.stringify({ issueNumber, ...result }, null, 2));

  const comment = buildComment(result);
  await upsertTriageComment(owner, repo, issueNumber, comment, token);

  const labelsToAdd = [];
  const labelsToRemove = new Set(['agent-approved', 'question', 'manual-only']);

  if (result.decision === 'pass') {
    labelsToAdd.push('agent-approved');
    labelsToRemove.delete('agent-approved');
  } else if (result.decision === 'manual-only') {
    labelsToAdd.push('manual-only');
    labelsToRemove.delete('manual-only');
  } else {
    labelsToAdd.push('question');
    labelsToRemove.delete('question');
  }

  await setLabels(owner, repo, issueNumber, labelsToAdd, [...labelsToRemove], token);

  if (projectsPat && projectId && statusFieldId) {
    const statusName =
      result.decision === 'pass'
        ? 'Ready'
        : result.decision === 'question'
          ? 'Backlog'
          : 'Human Reviewed';

    await updateProjectStatus({
      issue,
      projectId,
      statusFieldId,
      statusName,
      projectsPat,
    });
    console.log(`Project status updated to "${statusName}"`);
  } else {
    console.warn(
      'Skipping project status update: set GH_PROJECTS_PAT, GH_PROJECT_ID, and GH_STATUS_FIELD_ID to enable.',
    );
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
