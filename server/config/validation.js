/**
 * Small input-validation helpers shared by the auth routes.
 */

/** Minimum accepted password length (characters). */
export const MIN_PASSWORD_LENGTH = 8;

/**
 * Pragmatic email-format check: a single `@` separating a non-empty local part
 * and a domain with a dot, and no whitespace. Not a full RFC 5322 validator —
 * just enough to reject obviously malformed input.
 */
export function isValidEmail(email) {
  if (typeof email !== 'string') return false;
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim());
}

/** A password is accepted when it is at least [MIN_PASSWORD_LENGTH] chars. */
export function isStrongPassword(password) {
  return typeof password === 'string' && password.length >= MIN_PASSWORD_LENGTH;
}
