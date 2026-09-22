#!/usr/bin/env node
/**
 * Contract check: shared/care_taxonomy.json shape matches server expectations.
 * Dart parity is enforced by flutter test/features/care_taxonomy/.
 */
'use strict';

const fs = require('fs');
const path = require('path');

const REPO_ROOT = path.resolve(__dirname, '..', '..');
const TAXONOMY_PATH = path.join(REPO_ROOT, 'shared', 'care_taxonomy.json');

function fail(msg) {
  console.error(`validate_care_taxonomy_contract: ${msg}`);
  process.exit(1);
}

const taxonomy = JSON.parse(fs.readFileSync(TAXONOMY_PATH, 'utf8'));
const requiredFamilies = [
  'medication',
  'vaccination',
  'parasite_prevention',
  'wellness_review',
  'dental',
  'weight_monitoring',
  'grooming',
  'nail_care',
  'other',
];

for (const family of requiredFamilies) {
  const def = taxonomy.families[family];
  if (!def) fail(`missing family: ${family}`);
  for (const setting of taxonomy.care_settings) {
    if (!def.derived_legacy_type[setting]) {
      fail(`${family} missing derived_legacy_type.${setting}`);
    }
    if (!taxonomy.legacy_health_entry_types.includes(def.derived_legacy_type[setting])) {
      fail(`${family}.${setting} maps to invalid legacy type`);
    }
  }
  if (!taxonomy.filter_groups.includes(def.filter_group)) {
    fail(`${family} has invalid filter_group`);
  }
}

console.log('validate_care_taxonomy_contract: OK');
process.exit(0);
