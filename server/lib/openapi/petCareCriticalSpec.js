import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SPEC_PATH = path.resolve(
  __dirname,
  '../../../docs/architecture/openapi/pet-care-critical.json',
);

let cached;

export function loadPetCareCriticalSpec() {
  if (!cached) {
    cached = JSON.parse(fs.readFileSync(SPEC_PATH, 'utf8'));
  }
  return cached;
}

export function schemaRef(spec, ref) {
  const parts = ref.replace('#/', '').split('/');
  let node = spec;
  for (const part of parts) {
    node = node[part];
  }
  return node;
}

export function responseSchema(spec, pathKey, method, status) {
  const responses = spec.paths[pathKey]?.[method]?.responses;
  const entry = responses?.[String(status)];
  const ref = entry?.content?.['application/json']?.schema?.$ref;
  if (ref) return schemaRef(spec, ref);
  return entry?.content?.['application/json']?.schema;
}
