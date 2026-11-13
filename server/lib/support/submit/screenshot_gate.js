import { validateOrgImageMime } from '../../safeUpload.js';
import { collectSupportUploadFiles } from '../screenshots/collectFiles.js';
import {
  SUPPORT_SCREENSHOT_EXTENSIONS,
  SUPPORT_SCREENSHOT_MAX_BYTES_PER_FILE,
  SUPPORT_SCREENSHOT_MAX_BYTES_TOTAL,
  SUPPORT_SCREENSHOT_MAX_FILES,
} from '../screenshots/constants.js';

/**
 * Signed-in screenshot rules (R-008). Rejects signed-out multipart uploads.
 * @param {import('express').Request} req
 * @param {{ status: string }} auth from resolveSupportSubmitAuth
 * @returns {{ allowed: true, files: import('express').Multer.File[] } | { allowed: false, status: number, body: object }}
 */
export function assertSupportScreenshotGate(req, auth) {
  const files = collectSupportUploadFiles(req);
  if (files.length === 0) {
    return { allowed: true, files: [] };
  }

  if (auth.status !== 'signed_in') {
    return {
      allowed: false,
      status: 403,
      body: { error: 'Screenshots require a signed-in account.' },
    };
  }

  if (files.length > SUPPORT_SCREENSHOT_MAX_FILES) {
    return {
      allowed: false,
      status: 400,
      body: { error: `At most ${SUPPORT_SCREENSHOT_MAX_FILES} screenshots are allowed.` },
    };
  }

  let totalBytes = 0;
  for (const file of files) {
    const size = file.buffer?.length ?? 0;
    if (size > SUPPORT_SCREENSHOT_MAX_BYTES_PER_FILE) {
      return {
        allowed: false,
        status: 400,
        body: { error: 'Each screenshot must be 2 MB or smaller.' },
      };
    }
    totalBytes += size;
    try {
      validateOrgImageMime(file.mimetype, file.buffer, SUPPORT_SCREENSHOT_EXTENSIONS);
    } catch {
      return {
        allowed: false,
        status: 400,
        body: { error: 'Only PNG, JPEG, and WebP screenshots are allowed.' },
      };
    }
  }

  if (totalBytes > SUPPORT_SCREENSHOT_MAX_BYTES_TOTAL) {
    return {
      allowed: false,
      status: 400,
      body: { error: 'Total screenshot size must be 6 MB or less.' },
    };
  }

  return { allowed: true, files };
}
