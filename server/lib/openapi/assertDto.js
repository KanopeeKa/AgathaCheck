/**
 * Minimal JSON Schema subset validator for OpenAPI contract tests (F-14).
 * Supports types, required, properties, additionalProperties, $ref, oneOf, const, pattern.
 */

function resolveRef(root, ref) {
  if (!ref.startsWith('#/')) {
    throw new Error(`Unsupported $ref: ${ref}`);
  }
  const parts = ref.slice(2).split('/');
  let node = root;
  for (const part of parts) {
    node = node?.[part];
    if (node === undefined) {
      throw new Error(`Unresolved $ref: ${ref}`);
    }
  }
  return node;
}

function assertType(value, type, path) {
  if (type === 'integer') {
    if (typeof value !== 'number' || !Number.isInteger(value)) {
      throw new Error(`${path}: expected integer`);
    }
    return;
  }
  if (type === 'null') {
    if (value !== null) throw new Error(`${path}: expected null`);
    return;
  }
  if (typeof value !== type) {
    throw new Error(`${path}: expected ${type}, got ${typeof value}`);
  }
}

export function assertMatchesSchema(root, schema, value, path = '$') {
  if (schema.$ref) {
    return assertMatchesSchema(root, resolveRef(root, schema.$ref), value, path);
  }

  if (schema.oneOf) {
    const errors = [];
    for (const option of schema.oneOf) {
      try {
        assertMatchesSchema(root, option, value, path);
        return;
      } catch (err) {
        errors.push(err.message);
      }
    }
    throw new Error(`${path}: no oneOf branch matched (${errors.join('; ')})`);
  }

  if (schema.const !== undefined && value !== schema.const) {
    throw new Error(`${path}: expected const ${schema.const}`);
  }

  if (Array.isArray(schema.type)) {
    const ok = schema.type.some((t) => {
      if (t === 'null') return value === null;
      if (value === null) return false;
      return typeof value === t || (t === 'integer' && Number.isInteger(value));
    });
    if (!ok) {
      throw new Error(`${path}: expected one of [${schema.type.join(', ')}]`);
    }
    if (value === null) return;
  } else if (schema.type) {
    assertType(value, schema.type, path);
  }

  if (schema.pattern && typeof value === 'string' && !new RegExp(schema.pattern).test(value)) {
    throw new Error(`${path}: string does not match pattern ${schema.pattern}`);
  }

  if (schema.minimum !== undefined && value < schema.minimum) {
    throw new Error(`${path}: below minimum ${schema.minimum}`);
  }

  if (schema.type === 'array' || (Array.isArray(schema.type) && schema.type.includes('array'))) {
    if (!Array.isArray(value)) throw new Error(`${path}: expected array`);
    if (schema.items) {
      value.forEach((item, i) => assertMatchesSchema(root, schema.items, item, `${path}[${i}]`));
    }
    return;
  }

  if (schema.type === 'object' || schema.properties) {
    if (typeof value !== 'object' || value === null || Array.isArray(value)) {
      throw new Error(`${path}: expected object`);
    }
    for (const key of schema.required || []) {
      if (!(key in value)) {
        throw new Error(`${path}: missing required property "${key}"`);
      }
    }
    for (const [key, propSchema] of Object.entries(schema.properties || {})) {
      if (key in value) {
        assertMatchesSchema(root, propSchema, value[key], `${path}.${key}`);
      }
    }
    if (schema.additionalProperties === false) {
      const allowed = new Set([
        ...(schema.required || []),
        ...Object.keys(schema.properties || {}),
      ]);
      for (const key of Object.keys(value)) {
        if (!allowed.has(key)) {
          throw new Error(`${path}: unexpected property "${key}"`);
        }
      }
    }
  }
}
