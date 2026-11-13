import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SPEC_PATH = path.resolve(
  __dirname,
  '../../../docs/architecture/openapi/support-tickets.json',
);

let cached;

export function loadSupportTicketsSpec() {
  if (!cached) {
    cached = JSON.parse(fs.readFileSync(SPEC_PATH, 'utf8'));
  }
  return cached;
}

export function supportTicketsResponseSchema(spec, pathKey, method, status) {
  const responses = spec.paths[pathKey]?.[method]?.responses;
  const entry = responses?.[String(status)];
  const ref = entry?.content?.['application/json']?.schema?.$ref;
  if (ref) {
    const parts = ref.replace('#/', '').split('/');
    let node = spec;
    for (const part of parts) {
      node = node[part];
    }
    return node;
  }
  return entry?.content?.['application/json']?.schema;
}
