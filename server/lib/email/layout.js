import {
  APP_NAME,
  getPublicHost,
  getPublicUrl,
  LOGO_CID,
  PRIMARY_COLOR,
  PRIMARY_COLOR_HOVER,
} from './branding.js';

function escapeHtml(value) {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

/**
 * Wrap transactional email body HTML in a shared Agatha Track layout.
 *
 * @param {object} options
 * @param {string} options.title - Main heading shown in the email body.
 * @param {string} [options.preheader] - Hidden inbox preview line.
 * @param {string} options.bodyHtml - Inner HTML (already escaped where needed).
 * @param {string} [options.ctaUrl] - Optional primary button URL.
 * @param {string} [options.ctaLabel] - Optional primary button label.
 */
export function renderEmailLayout({ title, preheader = '', bodyHtml, ctaUrl, ctaLabel }) {
  const safeTitle = escapeHtml(title);
  const safePreheader = escapeHtml(preheader);
  const publicUrl = getPublicUrl();
  const publicHost = getPublicHost();

  const ctaBlock =
    ctaUrl && ctaLabel
      ? `<tr>
          <td style="padding:24px 0 8px 0;">
            <a href="${escapeHtml(ctaUrl)}"
               style="display:inline-block;background-color:${PRIMARY_COLOR};color:#ffffff;text-decoration:none;font-family:Arial,Helvetica,sans-serif;font-size:16px;font-weight:bold;line-height:1;padding:14px 28px;border-radius:8px;">
              ${escapeHtml(ctaLabel)}
            </a>
          </td>
        </tr>`
      : '';

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="color-scheme" content="light">
  <meta name="supported-color-schemes" content="light">
  <title>${safeTitle}</title>
</head>
<body style="margin:0;padding:0;background-color:#f5f5f5;">
  <div style="display:none;max-height:0;overflow:hidden;opacity:0;color:transparent;mso-hide:all;">
    ${safePreheader}
  </div>
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color:#f5f5f5;padding:24px 12px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:560px;background-color:#ffffff;border:1px solid #e8e8e8;border-radius:12px;">
          <tr>
            <td style="padding:28px 32px 16px 32px;">
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">
                <tr>
                  <td style="vertical-align:middle;width:48px;padding-right:12px;">
                    <img src="cid:${LOGO_CID}" width="48" height="48" alt="${escapeHtml(APP_NAME)} logo" style="display:block;border:0;border-radius:8px;">
                  </td>
                  <td style="vertical-align:middle;font-family:Arial,Helvetica,sans-serif;font-size:20px;font-weight:bold;color:#1f1f1f;">
                    ${escapeHtml(APP_NAME)}
                  </td>
                </tr>
              </table>
              <div style="height:3px;background-color:${PRIMARY_COLOR};border-radius:2px;margin-top:20px;"></div>
            </td>
          </tr>
          <tr>
            <td style="padding:8px 32px 32px 32px;font-family:Arial,Helvetica,sans-serif;color:#333333;font-size:16px;line-height:1.5;">
              <h1 style="margin:0 0 16px 0;font-size:22px;line-height:1.3;color:#1f1f1f;">${safeTitle}</h1>
              ${bodyHtml}
              ${ctaBlock}
              <p style="margin:32px 0 0 0;font-size:14px;line-height:1.5;color:#666666;">
                — ${escapeHtml(APP_NAME)}<br>
                <a href="${escapeHtml(publicUrl)}" style="color:${PRIMARY_COLOR};text-decoration:none;">${escapeHtml(publicHost)}</a>
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;
}

/** Render a highlighted monospace code block for one-time codes. */
export function renderCodeBlock(code) {
  const safeCode = escapeHtml(code);
  return `<p style="margin:0 0 8px 0;font-size:14px;color:#555555;">&nbsp;</p>
<table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin:0 0 16px 0;">
  <tr>
    <td style="background-color:#f3eefb;border:1px solid #d9cfe8;border-radius:8px;padding:16px 24px;font-family:Consolas,'Courier New',monospace;font-size:28px;font-weight:bold;letter-spacing:6px;color:${PRIMARY_COLOR};text-align:center;">
      ${safeCode}
    </td>
  </tr>
</table>`;
}

export { PRIMARY_COLOR, PRIMARY_COLOR_HOVER };
