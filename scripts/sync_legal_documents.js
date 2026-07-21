#!/usr/bin/env node
/**
 * Copies legal markdown from regulatory/legal/ into flutter_app/assets/legal/,
 * replacing date placeholders and internal link stubs.
 *
 * Usage: node scripts/sync_legal_documents.js [--date=YYYY-MM-DD]
 */

'use strict';

const { readFileSync, writeFileSync, mkdirSync, existsSync } = require('fs');
const { dirname } = require('path');

const EN_MONTHS = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const FR_MONTHS = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];

function formatEnglishDate(y, m, d) {
  return `${d} ${EN_MONTHS[m]} ${y}`;
}

function formatFrenchDate(y, m, d) {
  return `${d} ${FR_MONTHS[m]} ${y}`;
}

function parseDate(args) {
  for (const arg of args) {
    if (arg.startsWith('--date=')) {
      const raw = arg.substring('--date='.length);
      const m = raw.match(/^(\d{4})-(\d{2})-(\d{2})$/);
      if (!m) {
        console.error(`Invalid --date format: ${raw}. Expected YYYY-MM-DD.`);
        process.exit(1);
      }
      const y = parseInt(m[1], 10);
      const month = parseInt(m[2], 10) - 1;
      const d = parseInt(m[3], 10);
      if (month < 0 || month > 11 || d < 1 || d > 31) {
        console.error(`Invalid --date value: ${raw}.`);
        process.exit(1);
      }
      return { y, m: month, d };
    }
  }
  const now = new Date();
  return { y: now.getFullYear(), m: now.getMonth(), d: now.getDate() };
}

function transformContent(content, { isFrench, enDate, frDate }) {
  const privacyRoute = '/legal/privacy-notice';

  let transformed = content
    .replaceAll('[insert date]', enDate)
    .replaceAll('[à compléter]', frDate)
    .replaceAll('(link-to-privacy-notice)', `(${privacyRoute})`)
    .replaceAll('(lien-vers-la-politique)', `(${privacyRoute})`)
    .replaceAll('(link)', `(${privacyRoute})`)
    .replaceAll('(lien)', `(${privacyRoute})`)
    .replaceAll(
      '[link to sub-processor list or Privacy Notice section]',
      `[Privacy Notice](${privacyRoute})`,
    )
    .replaceAll(
      '[lien vers la liste des sous-traitants ou section de la Politique de confidentialité]',
      `[Politique de confidentialité](${privacyRoute})`,
    );

  if (isFrench) {
    transformed = transformed.replaceAll('[insert date]', frDate);
  } else {
    transformed = transformed.replaceAll('[à compléter]', enDate);
  }

  return transformed;
}

const pairs = [
  { source: 'regulatory/legal/en/terms-of-use.md', target: 'flutter_app/assets/legal/en/terms-of-use.md' },
  { source: 'regulatory/legal/en/privacy-notice.md', target: 'flutter_app/assets/legal/en/privacy-notice.md' },
  { source: 'regulatory/legal/en/legal-notice.md', target: 'flutter_app/assets/legal/en/legal-notice.md' },
  { source: 'regulatory/legal/en/dpa.md', target: 'flutter_app/assets/legal/en/dpa.md' },
  { source: 'regulatory/legal/fr/conditions-dutilisation.md', target: 'flutter_app/assets/legal/fr/conditions-dutilisation.md' },
  { source: 'regulatory/legal/fr/politique-de-confidentialite.md', target: 'flutter_app/assets/legal/fr/politique-de-confidentialite.md' },
  { source: 'regulatory/legal/fr/mentions-legales.md', target: 'flutter_app/assets/legal/fr/mentions-legales.md' },
  { source: 'regulatory/legal/fr/dpa.md', target: 'flutter_app/assets/legal/fr/dpa.md' },
];

const date = parseDate(process.argv.slice(2));
const enDate = formatEnglishDate(date.y, date.m, date.d);
const frDate = formatFrenchDate(date.y, date.m, date.d);

let exitCode = 0;
for (const pair of pairs) {
  if (!existsSync(pair.source)) {
    console.error(`Missing source file: ${pair.source}`);
    exitCode = 1;
    continue;
  }

  let content = readFileSync(pair.source, 'utf-8');
  const isFrench = pair.source.includes('/fr/');
  content = transformContent(content, { isFrench, enDate, frDate });

  mkdirSync(dirname(pair.target), { recursive: true });
  writeFileSync(pair.target, content);
  console.log(`Wrote ${pair.target}`);
}

const manifestPath = 'flutter_app/pubspec.yaml';
const manifest = readFileSync(manifestPath, 'utf-8');
if (!manifest.includes('assets/legal/')) {
  console.error(
    'Warning: flutter_app/pubspec.yaml does not list assets/legal/. ' +
    'Ensure legal assets are registered.',
  );
}

process.exit(exitCode);
