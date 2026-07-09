#!/usr/bin/env node
'use strict';

/**
 * Print GitHub Project v2 IDs needed for issue automation.
 *
 * Usage (user-owned repo):
 *   GH_PROJECTS_PAT=ghp_... node .github/scripts/discover-project-ids.js --user <github-login>
 *
 * Usage (organization-owned repo):
 *   GH_PROJECTS_PAT=ghp_... node .github/scripts/discover-project-ids.js --org <org-login>
 *
 * Requires a classic PAT with `read:project` (or `project`) and `repo` scopes.
 */

const { graphql } = require('./github-project-lib');

const PROJECTS_QUERY = `
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
`;

function printProjects(ownerLabel, projects) {
  if (projects.length === 0) {
    console.log(`No projects found for ${ownerLabel}.`);
    return;
  }

  console.log(`Projects for ${ownerLabel}:\n`);
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
}

async function main() {
  const token = process.env.GH_PROJECTS_PAT;
  if (!token) {
    throw new Error('Set GH_PROJECTS_PAT to a PAT with project read access.');
  }

  const args = process.argv.slice(2);
  let mode = 'org';
  let login = null;

  for (let i = 0; i < args.length; i += 1) {
    if (args[i] === '--user') {
      mode = 'user';
      login = args[i + 1];
      i += 1;
    } else if (args[i] === '--org') {
      mode = 'org';
      login = args[i + 1];
      i += 1;
    } else if (!login) {
      login = args[i];
    }
  }

  if (!login) {
    throw new Error(
      'Usage: node .github/scripts/discover-project-ids.js --user <login> | --org <login>',
    );
  }

  const query =
    mode === 'user'
      ? `query($login: String!) { user(login: $login) { ${PROJECTS_QUERY} } }`
      : `query($login: String!) { organization(login: $login) { ${PROJECTS_QUERY} } }`;

  const data = await graphql(token, query, { login });
  const owner = mode === 'user' ? data.user : data.organization;
  const projects = owner?.projectsV2?.nodes || [];

  printProjects(`${mode} ${login}`, projects);

  console.log('Add these repository secrets in GitHub → Settings → Secrets and variables → Actions:');
  console.log('  - GH_PROJECTS_PAT');
  console.log('  - GH_PROJECT_ID');
  console.log('  - GH_STATUS_FIELD_ID');
  console.log('  - cursor_api_key  (Cursor User API Key: github-actions-pawpet-automation)');
}

main().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
