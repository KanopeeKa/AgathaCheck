const LIMITS = {
  name: 200,
  phone: 50,
  email: 254,
  address: 500,
  website: 500,
  private_note: 5000,
};

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function trimOrNull(value) {
  if (value == null) return null;
  const s = String(value).trim();
  return s.length ? s : null;
}

function checkLength(field, value, max) {
  if (value == null || value === '') return null;
  if (String(value).length > max) {
    return `${field} is too long`;
  }
  return null;
}

/**
 * @param {object} body
 * @param {{ requireName?: boolean }} [opts]
 */
export function validateContactInput(body, opts = {}) {
  const requireName = opts.requireName ?? false;
  if (requireName || body.name != null) {
    const name = trimOrNull(body.name);
    if (!name) return { error: 'Name is required' };
    const len = checkLength('name', name, LIMITS.name);
    if (len) return { error: len };
  }

  if (body.email !== undefined) {
    const email = trimOrNull(body.email);
    if (email && !EMAIL_RE.test(email)) {
      return { error: 'Invalid email' };
    }
    const len = checkLength('email', email, LIMITS.email);
    if (len) return { error: len };
  }

  if (body.phone !== undefined) {
    const len = checkLength('phone', trimOrNull(body.phone), LIMITS.phone);
    if (len) return { error: len };
  }
  if (body.address !== undefined) {
    const len = checkLength('address', trimOrNull(body.address), LIMITS.address);
    if (len) return { error: len };
  }
  if (body.website !== undefined) {
    const website = trimOrNull(body.website);
    if (website) {
      const normalized = website.startsWith('http') ? website : `https://${website}`;
      try {
        const u = new URL(normalized);
        if (!['http:', 'https:'].includes(u.protocol)) {
          return { error: 'Invalid website' };
        }
      } catch {
        return { error: 'Invalid website' };
      }
    }
    const len = checkLength('website', website, LIMITS.website);
    if (len) return { error: len };
  }

  const note = body.private_note ?? body.privateNote;
  if (note !== undefined) {
    const len = checkLength('private_note', String(note), LIMITS.private_note);
    if (len) return { error: len };
  }

  return {};
}
