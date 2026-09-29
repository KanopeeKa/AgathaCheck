/**
 * Error thrown by care commands; routes map it to an HTTP status and body.
 * Throwing inside `withCareItemLock` rolls the whole command back.
 */
export class CareCommandError extends Error {
  /**
   * @param {number} status HTTP status
   * @param {string} code stable machine code (e.g. `occurrence_not_open`)
   * @param {string} message
   * @param {object} [details] extra body fields
   */
  constructor(status, code, message, details = {}) {
    super(message);
    this.name = 'CareCommandError';
    this.status = status;
    this.code = code;
    this.details = details;
  }

  toBody() {
    return { error: this.message, code: this.code, ...this.details };
  }
}

export function notOpen(message = 'This date is no longer open') {
  return new CareCommandError(409, 'occurrence_not_open', message);
}

export function badRequest(code, message, details = {}) {
  return new CareCommandError(400, code, message, details);
}
