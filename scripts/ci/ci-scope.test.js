'use strict';

const { spawnSync } = require('child_process');
const path = require('path');

const script = path.join(__dirname, 'ci-scope.test.sh');
const result = spawnSync('bash', [script], { stdio: 'inherit' });
if (result.status !== 0) {
  process.exit(result.status ?? 1);
}
