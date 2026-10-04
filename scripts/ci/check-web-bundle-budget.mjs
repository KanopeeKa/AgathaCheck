#!/usr/bin/env node
/**
 * Enforce scripts/ci/web-bundle-budget.json against flutter_app/build/web.
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const webDir = path.join(root, 'flutter_app/build/web');
const budgetPath = path.join(root, 'scripts/ci/web-bundle-budget.json');

function dirSizeBytes(dir) {
  let total = 0;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) total += dirSizeBytes(full);
    else if (entry.isFile()) total += fs.statSync(full).size;
  }
  return total;
}

function main() {
  const budget = JSON.parse(fs.readFileSync(budgetPath, 'utf8'));
  if (!fs.existsSync(webDir)) {
    console.error(`check-web-bundle-budget: missing ${webDir} — run Flutter web build first`);
    process.exit(1);
  }
  const bytes = dirSizeBytes(webDir);
  const max = budget.maxTotalBytes;
  if (bytes > max) {
    console.error(
      `check-web-bundle-budget: ${bytes} bytes exceeds budget ${max} (${webDir})`,
    );
    process.exit(1);
  }
  console.log(`check-web-bundle-budget: OK total ${bytes} / ${max} bytes`);

  const mainJs = path.join(webDir, 'main.dart.js');
  const mainMjs = path.join(webDir, 'main.dart.mjs');
  const mainPath = fs.existsSync(mainJs) ? mainJs : mainMjs;
  if (budget.maxMainDartJsBytes && fs.existsSync(mainPath)) {
    const mainBytes = fs.statSync(mainPath).size;
    const mainMax = budget.maxMainDartJsBytes;
    if (mainBytes > mainMax) {
      console.error(
        `check-web-bundle-budget: ${mainPath} ${mainBytes} bytes exceeds main.dart.js budget ${mainMax}`,
      );
      process.exit(1);
    }
    console.log(`check-web-bundle-budget: OK main ${mainBytes} / ${mainMax} bytes`);
  }
}

main();
