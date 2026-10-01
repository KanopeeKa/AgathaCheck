import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

/** Monorepo checkout (server/ + shared/) vs FTP backend bundle (backend/shared/). */
const TAXONOMY_CANDIDATES = [
  path.resolve(__dirname, '../../../shared/care_taxonomy.json'),
  path.resolve(__dirname, '../../../../shared/care_taxonomy.json'),
];

let cachedTaxonomy = null;

function resolveTaxonomyPath() {
  for (const candidate of TAXONOMY_CANDIDATES) {
    if (fs.existsSync(candidate)) return candidate;
  }
  throw new Error(
    `care taxonomy file not found (tried: ${TAXONOMY_CANDIDATES.join(', ')})`,
  );
}

/**
 * @returns {import('./types.js').CareTaxonomy}
 */
export function loadCareTaxonomy() {
  if (cachedTaxonomy) return cachedTaxonomy;
  const raw = fs.readFileSync(resolveTaxonomyPath(), 'utf8');
  cachedTaxonomy = JSON.parse(raw);
  return cachedTaxonomy;
}

/** @param {import('./types.js').CareTaxonomy | null} taxonomy */
export function resetCareTaxonomyCache(taxonomy = null) {
  cachedTaxonomy = taxonomy;
}
