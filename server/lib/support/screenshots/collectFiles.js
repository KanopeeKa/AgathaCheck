/**
 * Normalise multer output into a flat file list.
 * @param {import('express').Request} req
 * @returns {import('express').Multer.File[]}
 */
export function collectSupportUploadFiles(req) {
  const raw = req.files;
  if (Array.isArray(raw)) {
    return raw.filter((f) => f && Buffer.isBuffer(f.buffer) && f.buffer.length > 0);
  }
  if (raw && typeof raw === 'object') {
    const list = [];
    for (const value of Object.values(raw)) {
      if (Array.isArray(value)) {
        list.push(
          ...value.filter((f) => f && Buffer.isBuffer(f.buffer) && f.buffer.length > 0),
        );
      }
    }
    return list;
  }
  return [];
}
