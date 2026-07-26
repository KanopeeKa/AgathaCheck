#!/usr/bin/env node
'use strict';

const https = require('node:https');
const { isUatPromoteTagJobSkipped } = require('./uat-promote-tag-job-skipped');

const runId = process.argv[2];
const repo = process.env.GITHUB_REPOSITORY;
const token = process.env.GITHUB_TOKEN;

if (!runId || !repo || !token) {
  process.exit(0);
}

function api(path) {
  return new Promise((resolve, reject) => {
    const req = https.request(
      {
        hostname: 'api.github.com',
        path,
        headers: {
          Authorization: `Bearer ${token}`,
          Accept: 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28',
          'User-Agent': 'agatha-check-ci',
        },
      },
      (res) => {
        let body = '';
        res.on('data', (chunk) => {
          body += chunk;
        });
        res.on('end', () => {
          if (res.statusCode && res.statusCode >= 400) {
            reject(new Error(`HTTP ${res.statusCode}: ${body.slice(0, 200)}`));
            return;
          }
          resolve(JSON.parse(body));
        });
      },
    );
    req.on('error', reject);
    req.end();
  });
}

api(`/repos/${repo}/actions/runs/${runId}/jobs`)
  .then((payload) => {
    if (isUatPromoteTagJobSkipped(payload.jobs)) {
      process.stdout.write('promote_tag_skipped');
    }
  })
  .catch((err) => {
    console.error(`::warning::promote-tag job lookup failed (${err.message}); continuing to tag resolution`);
    process.exit(0);
  });
