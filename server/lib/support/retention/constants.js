/** Daily scheduler key (once per UTC day). */
export const SUPPORT_RETENTION_JOB_KEY = 'support_retention';

/** D-007 — retention from submission. */
export const SUPPORT_TICKET_RETENTION_SQL = `NOW() - INTERVAL '12 months'`;
export const SUPPORT_SCREENSHOT_RETENTION_SQL = `NOW() - INTERVAL '90 days'`;
