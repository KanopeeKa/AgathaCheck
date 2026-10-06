'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const { test } = require('node:test');

const SCRIPT = path.join(__dirname, 'check_file_size.js');

function repoWith(files, allowlist) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'file-size-'));
  for (const [rel, lines] of Object.entries(files)) {
    const file = path.join(root, rel);
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(file, '// line\n'.repeat(lines));
  }
  if (allowlist) {
    fs.mkdirSync(path.join(root, 'scripts'), { recursive: true });
    fs.writeFileSync(
      path.join(root, 'scripts/file-size-allowlist.json'),
      JSON.stringify(allowlist, null, 2),
    );
  }
  fs.mkdirSync(path.join(root, 'docs/engineering/frozen-domains'), { recursive: true });
  fs.writeFileSync(
    path.join(root, 'docs/engineering/frozen-domains/manifest.json'),
    JSON.stringify({ sourceRoots: [], serverRoots: [] }),
  );
  return root;
}

function run(root, extraArgs = []) {
  const res = spawnSync(process.execPath, [SCRIPT, '--root', root, ...extraArgs], {
    encoding: 'utf8',
  });
  return { code: res.status, out: `${res.stdout}${res.stderr}` };
}

test('a 501-line file under server/routes still fails (blocking root)', () => {
  const res = run(repoWith({ 'server/routes/big.js': 501 }));
  assert.equal(res.code, 1);
  assert.match(res.out, /\[501 lines\] server\/routes\/big\.js/);
});

test('a 501-line file under server/lib fails when not allowlisted (D7 blocking)', () => {
  const res = run(repoWith({ 'server/lib/big.js': 501, 'server/services/ok.js': 20 }));
  assert.equal(res.code, 1);
  assert.match(res.out, /\[501 lines\] server\/lib\/big\.js/);
  assert.doesNotMatch(res.out, /Report-only \(D7\)/);
});

test('a 501-line file under server/services fails when not allowlisted', () => {
  const res = run(repoWith({ 'server/services/sharing/big.js': 501 }));
  assert.equal(res.code, 1);
  assert.match(res.out, /server\/services\/sharing\/big\.js/);
});

test('allowlisted server/lib file growing past maxLines fails', () => {
  const root = repoWith(
    { 'server/lib/big.js': 502 },
    {
      'server/lib/big.js': {
        maxLines: 501,
        owner: 'test',
        reason: 'fixture',
        review_date: '2099-01-01',
      },
    },
  );
  const res = run(root);
  assert.equal(res.code, 1);
  assert.match(res.out, /grew beyond ratchet ceiling 501/);
});

test('expired review_date on allowlist emits warning without failing alone', () => {
  const root = repoWith(
    { 'server/lib/big.js': 400 },
    {
      'server/lib/big.js': {
        maxLines: 501,
        owner: 'test',
        reason: 'fixture',
        review_date: '2000-01-01',
      },
    },
  );
  const res = run(root);
  assert.equal(res.code, 0);
  assert.match(res.out, /::warning::.*review date\(s\) passed/);
  assert.match(res.out, /server\/lib\/big\.js/);
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

test('Flutter size summary includes classification buckets', () => {
  const root = repoWith({
    'flutter_app/lib/features/x/presentation/screens/a_screen.dart': 10,
    'flutter_app/lib/features/x/presentation/widgets/w.dart': 10,
    'flutter_app/lib/features/x/data/m.dart': 10,
  });
  const res = run(root);
  assert.equal(res.code, 0);
  assert.match(res.out, /Flutter size summary/);
  assert.match(res.out, /screens:/);
  assert.match(res.out, /widgets:/);
  assert.match(res.out, /data:/);
});
