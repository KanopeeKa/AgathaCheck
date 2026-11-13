import { parseSupportContext } from './contextAllowlist.js';

const CATEGORIES = new Set(['bug', 'suggestion', 'account', 'billing']);
const FREQUENCIES = new Set(['always', 'sometimes', 'once']);

const LIMITS = {
  title: 120,
  description: 5000,
  steps: 3000,
  expected: 2000,
  actual: 2000,
  email: 254,
};

/**
 * @param {Record<string, unknown>} body
 * @param {{ signedIn: boolean }} options
 */
export function validateSupportTicketBody(body, { signedIn }) {
  const errors = [];
  const category = body?.category;
  if (typeof category !== 'string' || !CATEGORIES.has(category)) {
    errors.push('category must be bug, suggestion, account, or billing');
  }

  const title = typeof body?.title === 'string' ? body.title.trim() : '';
  if (!title) errors.push('title is required');
  else if (title.length > LIMITS.title) errors.push(`title must be at most ${LIMITS.title} characters`);

  const description = typeof body?.description === 'string' ? body.description : '';
  if (!description.trim()) errors.push('description is required');
  else if (description.length > LIMITS.description) {
    errors.push(`description must be at most ${LIMITS.description} characters`);
  }

  for (const field of ['expected', 'actual', 'steps']) {
    const value = body?.[field];
    if (value === undefined || value === null || value === '') continue;
    if (typeof value !== 'string') {
      errors.push(`${field} must be a string`);
      continue;
    }
    if (value.length > LIMITS[field]) {
      errors.push(`${field} must be at most ${LIMITS[field]} characters`);
    }
  }

  let frequency = body?.frequency;
  if (frequency === undefined || frequency === null || frequency === '') {
    frequency = null;
  } else if (typeof frequency !== 'string' || !FREQUENCIES.has(frequency)) {
    errors.push('frequency must be always, sometimes, or once');
  }

  const locale = typeof body?.locale === 'string' ? body.locale.trim() : '';
  if (!locale) errors.push('locale is required');
  else if (locale.length > 16) errors.push('locale is too long');

  let email = null;
  if (!signedIn) {
    email = typeof body?.email === 'string' ? body.email.trim() : '';
    if (!email) errors.push('email is required when signed out');
    else if (email.length > LIMITS.email) errors.push(`email must be at most ${LIMITS.email} characters`);
  }

  const contextResult = parseSupportContext(body?.context);
  if (!contextResult.ok) {
    errors.push(contextResult.error);
  }

  if (errors.length > 0) {
    return { ok: false, errors };
  }

  return {
    ok: true,
    value: {
      category,
      title,
      description,
      expected: optionalString(body?.expected),
      actual: optionalString(body?.actual),
      steps: optionalString(body?.steps),
      frequency,
      locale,
      email,
      context: contextResult.context,
    },
  };
}

function optionalString(value) {
  if (value === undefined || value === null || value === '') return null;
  return String(value);
}
