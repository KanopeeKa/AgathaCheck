#!/usr/bin/env node
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { execFileSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const SCRIPT = path.join(__dirname, 'detect-deploy-package-changed.sh');

function runDetect(cwd, kind, deployRef) {
  const out = execFileSync('bash', [SCRIPT, '--kind', kind], {
    cwd,
    env: { ...process.env, DEPLOY_REF: deployRef },
    encoding: 'utf8',
  });
  const parsed = {};
  for (const line of out.trim().split('\n')) {
    const m = line.match(/^(changed|baseline_tag)=(.+)$/);
    if (m) parsed[m[1]] = m[2];
  }
  return parsed;
}

function initRepo(dir) {
  execFileSync('git', ['init'], { cwd: dir });
  execFileSync('git', ['config', 'user.email', 'test@example.com'], { cwd: dir });
  execFileSync('git', ['config', 'user.name', 'Test'], { cwd: dir });
  fs.mkdirSync(path.join(dir, 'server'), { recursive: true });
}

function commitAll(dir, message) {
  execFileSync('git', ['add', '-A'], { cwd: dir });
  execFileSync('git', ['commit', '-m', message], { cwd: dir });
}

test('detect-deploy-package-changed: uat detects package.json change since prior tag', () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'pkg-detect-uat-'));
  try {
    initRepo(dir);
    fs.writeFileSync(
      path.join(dir, 'server/package.json'),
      JSON.stringify({ name: 'app', dependencies: { express: '1' } }),
    );
    commitAll(dir, 'base');
    execFileSync('git', ['tag', 'uat-260901-100'], { cwd: dir });

    fs.writeFileSync(
      path.join(dir, 'server/package.json'),
      JSON.stringify({ name: 'app', dependencies: { express: '1', helmet: '8' } }),
    );
    commitAll(dir, 'add helmet');
    execFileSync('git', ['tag', 'uat-260902-101'], { cwd: dir });

    const result = runDetect(dir, 'uat', 'uat-260902-101');
    assert.equal(result.changed, 'true');
    assert.equal(result.baseline_tag, 'uat-260901-100');
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
});

test('detect-deploy-package-changed: uat unchanged when only server code moves', () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'pkg-detect-uat-clean-'));
  try {
    initRepo(dir);
    fs.writeFileSync(path.join(dir, 'server/package.json'), '{"name":"app"}');
    fs.writeFileSync(path.join(dir, 'server/index.js'), 'console.log(1)');
    commitAll(dir, 'base');
    execFileSync('git', ['tag', 'uat-260901-100'], { cwd: dir });

    fs.writeFileSync(path.join(dir, 'server/index.js'), 'console.log(2)');
    commitAll(dir, 'code only');
    execFileSync('git', ['tag', 'uat-260902-101'], { cwd: dir });

    const result = runDetect(dir, 'uat', 'uat-260902-101');
    assert.equal(result.changed, 'false');
    assert.equal(result.baseline_tag, 'uat-260901-100');
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
});

test('detect-deploy-package-changed: prod uses newest ancestor v tag as baseline', () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'pkg-detect-prod-'));
  try {
    initRepo(dir);
    fs.writeFileSync(path.join(dir, 'server/package.json'), '{"name":"app","dependencies":{}}');
    commitAll(dir, 'v1');
    execFileSync('git', ['tag', 'v1.0.0'], { cwd: dir });

    fs.writeFileSync(
      path.join(dir, 'server/package.json'),
      '{"name":"app","dependencies":{"helmet":"8"}}',
    );
    commitAll(dir, 'v2');

    const sha = execFileSync('git', ['rev-parse', 'HEAD'], { cwd: dir, encoding: 'utf8' }).trim();
    const result = runDetect(dir, 'prod', sha);
    assert.equal(result.changed, 'true');
    assert.equal(result.baseline_tag, 'v1.0.0');
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
});
