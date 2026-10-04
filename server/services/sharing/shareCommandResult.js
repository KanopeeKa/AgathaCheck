/**
 * Carries a command outcome through withTransaction without committing.
 */
export class ShareCommandResult extends Error {
  /**
   * @param {Record<string, unknown>} payload
   */
  constructor(payload) {
    super('ShareCommandResult');
    this.name = 'ShareCommandResult';
    this.payload = payload;
  }
}

/**
 * @param {unknown} err
 * @returns {Record<string, unknown>|null}
 */
export function unwrapShareCommandResult(err) {
  if (err instanceof ShareCommandResult) {
    return err.payload;
  }
  return null;
}
