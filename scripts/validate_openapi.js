#!/usr/bin/env node
/**
 * Validate the Pet Care critical OpenAPI subset (F-14).
 * Usage: node scripts/validate_openapi.js [--spec path]
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, '..');

const DEFAULT_SPEC = path.join(
  REPO_ROOT,
  'docs/architecture/openapi/pet-care-critical.json',
);

function fail(msg) {
  console.error(`validate_openapi: ${msg}`);
  process.exit(1);
}

function resolveRef(root, ref, seen = new Set()) {
  if (!ref.startsWith('#/')) fail(`unsupported $ref ${ref}`);
  if (seen.has(ref)) return;
  seen.add(ref);
  const parts = ref.slice(2).split('/');
  let node = root;
  for (const part of parts) {
    node = node?.[part];
    if (node === undefined) fail(`unresolved $ref ${ref}`);
  }
  if (node.$ref) resolveRef(root, node.$ref, seen);
  if (node.properties) {
    for (const prop of Object.values(node.properties)) {
      if (prop.$ref) resolveRef(root, prop.$ref, seen);
      if (prop.items?.$ref) resolveRef(root, prop.items.$ref, seen);
      if (prop.oneOf) {
        for (const option of prop.oneOf) {
          if (option.$ref) resolveRef(root, option.$ref, seen);
        }
      }
    }
  }
}

function validateSpec(spec) {
  if (!spec.openapi?.startsWith('3.')) {
    fail('openapi version must be 3.x');
  }
  if (!spec.info?.title || !spec.info?.version) {
    fail('info.title and info.version are required');
  }
  if (!spec.paths || Object.keys(spec.paths).length === 0) {
    fail('paths must be non-empty');
  }

  const httpMethods = new Set(['get', 'post', 'put', 'patch', 'delete', 'options', 'head']);
  for (const [route, methods] of Object.entries(spec.paths)) {
    if (!route.startsWith('/')) fail(`path must start with /: ${route}`);
    for (const [method, op] of Object.entries(methods)) {
      if (!httpMethods.has(method)) continue;
      if (!op.operationId) fail(`${method} ${route} missing operationId`);
      const responses = op.responses || {};
      if (Object.keys(responses).length === 0) {
        fail(`${method} ${route} has no responses`);
      }
      for (const [status, response] of Object.entries(responses)) {
        const schema = response?.content?.['application/json']?.schema;
        if (!schema) fail(`${method} ${route} ${status} missing application/json schema`);
        if (schema.$ref) resolveRef(spec, schema.$ref);
        if (schema.type === 'array' && schema.items?.$ref) {
          resolveRef(spec, schema.items.$ref);
        }
      }
    }
  }

  if (!spec.components?.schemas || Object.keys(spec.components.schemas).length === 0) {
    fail('components.schemas must be non-empty');
  }
}

function main() {
  const specArg = process.argv.includes('--spec')
    ? process.argv[process.argv.indexOf('--spec') + 1]
    : DEFAULT_SPEC;
  const specPath = path.resolve(specArg);
  if (!fs.existsSync(specPath)) fail(`spec not found: ${specPath}`);
  const spec = JSON.parse(fs.readFileSync(specPath, 'utf8'));
  validateSpec(spec);
  console.log(`validate_openapi: OK ${path.relative(REPO_ROOT, specPath)}`);
}

main();
