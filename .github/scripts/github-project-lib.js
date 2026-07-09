'use strict';

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
          url
          labels(first: 50) { nodes { name } }
          assignees(first: 10) { nodes { login } }
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

function getIssueProjectStatus(item, statusFieldId) {
  for (const fieldValue of item.fieldValues?.nodes || []) {
    if (fieldValue.field?.id === statusFieldId) {
      return fieldValue.name;
    }
  }
  return null;
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

async function listProjectIssues({ projectId, statusFieldId, projectsPat }) {
  const data = await graphql(
    projectsPat,
    `query($projectId: ID!) {
      node(id: $projectId) {
        ... on ProjectV2 {
          items(first: 100) {
            nodes {
              id
              fieldValues(first: 20) {
                nodes {
                  ... on ProjectV2ItemFieldSingleSelectValue {
                    name
                    field { ... on ProjectV2SingleSelectField { id name } }
                  }
                }
              }
              content {
                ... on Issue {
                  id
                  number
                  title
                  body
                  url
                  state
                  labels(first: 30) { nodes { name } }
                }
              }
            }
          }
        }
      }
    }`,
    { projectId },
  );

  const items = data.node?.items?.nodes || [];
  return items
    .map((item) => {
      const issue = item.content;
      if (!issue || issue.state !== 'OPEN') return null;
      return {
        projectItemId: item.id,
        status: getIssueProjectStatus(item, statusFieldId),
        issue,
      };
    })
    .filter(Boolean);
}

async function searchEligibleIssues(owner, repo, token) {
  const q = encodeURIComponent(
    `repo:${owner}/${repo} is:issue is:open label:agent-approved -label:busy -label:manual-only -label:question -label:blocked`,
  );
  const data = await rest('GET', `/search/issues?q=${q}&per_page=20`, token);
  return data.items || [];
}

async function upsertMarkerComment({
  owner,
  repo,
  issueNumber,
  marker,
  body,
  token,
}) {
  const comments = await rest(
    'GET',
    `/repos/${owner}/${repo}/issues/${issueNumber}/comments?per_page=100`,
    token,
  );
  const existing = comments.find((comment) => comment.body?.includes(marker));

  if (existing) {
    await rest(
      'PATCH',
      `/repos/${owner}/${repo}/issues/comments/${existing.id}`,
      token,
      { body },
    );
    return existing.id;
  }

  const created = await rest(
    'POST',
    `/repos/${owner}/${repo}/issues/${issueNumber}/comments`,
    token,
    { body },
  );
  return created.id;
}

async function setLabels(owner, repo, issueNumber, add, remove, token) {
  for (const label of remove) {
    await rest(
      'DELETE',
      `/repos/${owner}/${repo}/issues/${issueNumber}/labels/${encodeURIComponent(label)}`,
      token,
    ).catch(() => {});
  }

  if (add.length > 0) {
    await rest('POST', `/repos/${owner}/${repo}/issues/${issueNumber}/labels`, token, {
      labels: add,
    });
  }
}

async function assignIssue(owner, repo, issueNumber, assignee, token) {
  await rest('POST', `/repos/${owner}/${repo}/issues/${issueNumber}/assignees`, token, {
    assignees: [assignee],
  });
}

function parseRepo(repository) {
  const [owner, repo] = repository.split('/');
  if (!owner || !repo) {
    throw new Error(`Invalid GITHUB_REPOSITORY value: ${repository}`);
  }
  return { owner, repo };
}

function hasLabel(issue, labelName) {
  const labels = issue.labels?.nodes || issue.labels || [];
  return labels.some((label) => {
    const name = typeof label === 'string' ? label : label.name;
    return name.toLowerCase() === labelName.toLowerCase();
  });
}

module.exports = {
  graphql,
  rest,
  fetchIssue,
  getStatusOptionId,
  ensureProjectItem,
  updateProjectStatus,
  listProjectIssues,
  searchEligibleIssues,
  upsertMarkerComment,
  setLabels,
  assignIssue,
  parseRepo,
  hasLabel,
  getIssueProjectStatus,
};
