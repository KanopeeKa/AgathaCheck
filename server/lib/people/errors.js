/**
 * Typed People domain errors — wire shape is additive `{ error, code, details? }`.
 */
export class PeopleError extends Error {
  /**
   * @param {string} code stable snake_case
   * @param {number} status HTTP status
   * @param {string} message public error message
   * @param {Record<string, unknown>} [details]
   */
  constructor(code, status, message, details = undefined) {
    super(message);
    this.name = 'PeopleError';
    this.code = code;
    this.status = status;
    this.details = details;
  }

  toJson() {
    const body = { error: this.message, code: this.code };
    if (this.details !== undefined) {
      body.details = this.details;
    }
    return body;
  }
}

export const PEOPLE_ERROR_CODES = {
  VALIDATION_FAILED: 'validation_failed',
  CONTACT_NOT_FOUND: 'contact_not_found',
  FORBIDDEN: 'forbidden',
  CONTACT_IN_USE: 'contact_in_use',
  SLOT_CONFLICT: 'slot_conflict',
  LINKED_IDENTITY_READ_ONLY: 'linked_identity_read_only',
};

/**
 * @param {unknown} err
 * @returns {PeopleError|null}
 */
export function asPeopleError(err) {
  return err instanceof PeopleError ? err : null;
}
