#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const DOMAINS = path.join(ROOT, 'docs/domains');

function walkMd(dir, acc, prefix) {
  if (!fs.existsSync(dir)) {
    return;
  }
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      walkMd(full, acc, prefix);
    } else if (entry.name.endsWith('.md')) {
      acc.push(path.relative(ROOT, full).replace(/\\/g, '/'));
    }
  }
}

const features = [];
const changes = [];

for (const domain of fs.readdirSync(DOMAINS)) {
  const featDir = path.join(DOMAINS, domain, 'features');
  const chDir = path.join(DOMAINS, domain, 'changes');
  walkMd(featDir, features, domain);
  walkMd(chDir, changes, domain);
}

features.sort();
changes.sort();

const out = {
  version: 1,
  generated_at: new Date().toISOString().slice(0, 10),
  features,
  changes,
};

const target = path.join(ROOT, 'scripts/docs-legacy-baseline.json');
fs.writeFileSync(target, `${JSON.stringify(out, null, 2)}\n`);
console.log(`Wrote ${target}: ${features.length} features, ${changes.length} changes`);
