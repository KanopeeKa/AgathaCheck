'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const { test } = require('node:test');

const SCRIPT = path.join(__dirname, 'check_file_size.js');

function repoWith(files) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'file-size-'));
  for (const [rel, lines] of Object.entries(files)) {
    const file = path.join(root, rel);
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(file, '// line\n'.repeat(lines));
  }
  return root;
}

function run(root) {
  const res = spawnSync(process.execPath, [SCRIPT, '--root', root], { encoding: 'utf8' });
  return { code: res.status, out: `${res.stdout}${res.stderr}` };
}

test('a 501-line file under server/routes still fails (blocking root)', () => {
  const res = run(repoWith({ 'server/routes/big.js': 501 }));
  assert.equal(res.code, 1);
  assert.match(res.out, /\[501 lines\] server\/routes\/big\.js/);
});

test('a 501-line file under server/lib passes and is listed as report-only (D7)', () => {
  const res = run(repoWith({ 'server/lib/big.js': 501, 'server/services/ok.js': 20 }));
  assert.equal(res.code, 0);
  assert.match(res.out, /Report-only \(D7\): server\/lib, server\/services — 1 file\(s\) over 500 lines/);
  assert.match(res.out, /501 lines {2}server\/lib\/big\.js/);
  assert.doesNotMatch(res.out, /server\/services\/ok\.js/);
});

test('a 501-line file under server/services is report-only too', () => {
  const res = run(repoWith({ 'server/services/sharing/big.js': 501 }));
  assert.equal(res.code, 0);
  assert.match(res.out, /501 lines {2}server\/services\/sharing\/big\.js/);
});

test('Flutter lib files over the limit still fail; generated files are skipped', () => {
  const root = repoWith({
    'flutter_app/lib/features/x/big.dart': 501,
    'flutter_app/lib/features/x/big.g.dart': 900,
  });
  const res = run(root);
  assert.equal(res.code, 1);
  assert.match(res.out, /flutter_app\/lib\/features\/x\/big\.dart/);
  assert.doesNotMatch(res.out, /big\.g\.dart/);
});
