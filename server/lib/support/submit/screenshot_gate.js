/**
 * Phase 3: multipart uploads are rejected until phase 6 implements storage.
 * @param {import('express').Request} req
 * @returns {{ allowed: true } | { allowed: false, status: number, body: object }}
 */
export function assertSupportScreenshotGate(req) {
  const files = req.files;
  if (Array.isArray(files) && files.length > 0) {
    return {
      allowed: false,
      status: 400,
      body: { error: 'Screenshots are not accepted yet. Submit a text-only request.' },
    };
  }
  if (files && typeof files === 'object' && Object.keys(files).length > 0) {
    return {
      allowed: false,
      status: 400,
      body: { error: 'Screenshots are not accepted yet. Submit a text-only request.' },
    };
  }
  return { allowed: true };
}
