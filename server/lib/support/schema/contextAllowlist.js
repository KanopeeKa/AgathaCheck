const ALLOWED_CONTEXT_KEYS = new Set([
  'version',
  'build',
  'platform',
  'browser_family',
  'locale',
  'route_name',
  'client_time',
]);

/**
 * @param {unknown} raw
 * @returns {{ ok: true, context: Record<string, string> } | { ok: false, error: string }}
 */
export function parseSupportContext(raw) {
  if (raw === undefined || raw === null) {
    return { ok: true, context: {} };
  }
  if (typeof raw !== 'object' || Array.isArray(raw)) {
    return { ok: false, error: 'context must be an object' };
  }
  const context = {};
  for (const [key, value] of Object.entries(raw)) {
    if (!ALLOWED_CONTEXT_KEYS.has(key)) {
      return { ok: false, error: `Unknown context field: ${key}` };
    }
    if (value === null || value === undefined) {
      context[key] = '';
      continue;
    }
    if (typeof value !== 'string' && typeof value !== 'number') {
      return { ok: false, error: `context.${key} must be a string` };
    }
    context[key] = String(value);
  }
  return { ok: true, context };
}
