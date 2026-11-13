import crypto from 'crypto';

const CROCKFORD_BASE32 = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

/** @returns {string} e.g. AT-3K9H2M7P */
export function generateSupportTicketReference() {
  const bytes = crypto.randomBytes(8);
  let suffix = '';
  for (let i = 0; i < 8; i += 1) {
    suffix += CROCKFORD_BASE32[bytes[i] % 32];
  }
  return `AT-${suffix}`;
}
