import { redactJobError } from '../../jobs/redactJobError.js';

/** Persist-safe outbox error text (never ticket or reporter content). */
export function safeOutboxError(message) {
  return redactJobError(message);
}
