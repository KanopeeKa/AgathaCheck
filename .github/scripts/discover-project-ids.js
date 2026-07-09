#!/usr/bin/env node
'use strict';

/**
 * Print GitHub Project v2 IDs needed for issue triage automation.
 *
 * Usage:
 *   GH_PROJECTS_PAT=ghp_... node .github/scripts/discover-project-ids.js <org-login>
 *
 * Requires a classic PAT with `read:project` (or `project`) and `repo` scopes.
 */

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

async function main() {
  const token = process.env.GH_PROJECTS_PAT;
  const org = process.argv[2];

  if (!token) {
    throw new Error('Set GH_PROJECTS_PAT to a PAT with project read access.');
  }
  if (!org) {
    throw new Error('Usage: node .github/scripts/discover-project-ids.js <org-login>');
  }

  const data = await graphql(
    token,
    `query($org: String!) {
      organization(login: $org) {
        projectsV2(first: 50) {
          nodes {
            id
            title
            number
            fields(first: 50) {
              nodes {
                ... on ProjectV2Field {
                  __typename
                  id
                  name
                }
                ... on ProjectV2SingleSelectField {
                  __typename
                  id
                  name
                  options { id name }
                }
              }
            }
          }
        }
      }
    }`,
    { org },
  );

  const projects = data.organization?.projectsV2?.nodes || [];
  if (projects.length === 0) {
    console.log(`No projects found for organization "${org}".`);
    console.log(
      'If this repository is user-owned rather than organization-owned, Project automation via GraphQL may be limited. Move the repo to an organization or adjust the discovery query.',
    );
    return;
  }

  console.log(`Projects for organization: ${org}\n`);

  for (const project of projects) {
    console.log(`Project: ${project.title} (#${project.number})`);
    console.log(`  GH_PROJECT_ID=${project.id}`);

    const statusField = project.fields.nodes.find(
      (field) => field.name?.toLowerCase() === 'status',
    );

    if (!statusField) {
      console.log('  Status field: not found');
      console.log('');
      continue;
    }

    console.log(`  GH_STATUS_FIELD_ID=${statusField.id}`);
    if (statusField.options) {
      console.log('  Status options:');
      for (const option of statusField.options) {
        console.log(`    - ${option.name}: ${option.id}`);
      }
    }
    console.log('');
  }

  console.log('Add these repository secrets in GitHub → Settings → Secrets and variables → Actions:');
  console.log('  - GH_PROJECTS_PAT');
  console.log('  - GH_PROJECT_ID');
  console.log('  - GH_STATUS_FIELD_ID');
}

main().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
