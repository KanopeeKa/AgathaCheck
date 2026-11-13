/**
 * @param {import('express').Request} req
 * @returns {Record<string, unknown> | null}
 */
export function parseSupportTicketPayload(req) {
  const contentType = String(req.headers['content-type'] || '');
  if (contentType.includes('multipart/form-data')) {
    if (typeof req.body?.payload === 'string') {
      try {
        return JSON.parse(req.body.payload);
      } catch {
        return null;
      }
    }
    return req.body && typeof req.body === 'object' ? req.body : null;
  }
  if (req.body && typeof req.body === 'object') {
    return req.body;
  }
  return null;
}
