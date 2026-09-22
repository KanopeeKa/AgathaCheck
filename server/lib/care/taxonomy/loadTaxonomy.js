import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const TAXONOMY_PATH = path.resolve(__dirname, '../../../../shared/care_taxonomy.json');

let cachedTaxonomy = null;

/**
 * @returns {import('./types.js').CareTaxonomy}
 */
export function loadCareTaxonomy() {
  if (cachedTaxonomy) return cachedTaxonomy;
  const raw = fs.readFileSync(TAXONOMY_PATH, 'utf8');
  cachedTaxonomy = JSON.parse(raw);
  return cachedTaxonomy;
}

/** @param {import('./types.js').CareTaxonomy | null} taxonomy */
export function resetCareTaxonomyCache(taxonomy = null) {
  cachedTaxonomy = taxonomy;
}
