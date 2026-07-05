/**
 * Observability and audit retention defaults.
 * Override via environment variables in production.
 */

export const AUDIT_HOT_DAYS = Number(process.env.AUDIT_HOT_DAYS || 14);
export const AUDIT_WARM_DAYS = Number(process.env.AUDIT_WARM_DAYS || 90);
export const AUDIT_COLD_DAYS = Number(process.env.AUDIT_COLD_DAYS || 730);

export const AUDIT_PSEUDONYM_SALT =
  process.env.AUDIT_PSEUDONYM_SALT || process.env.JWT_SECRET || 'dev_audit_salt';

export const POSTHOG_HOST = process.env.POSTHOG_HOST || 'https://eu.posthog.com';
export const POSTHOG_PROJECT_ID = process.env.POSTHOG_PROJECT_ID || '';
export const POSTHOG_PERSONAL_API_KEY = process.env.POSTHOG_PERSONAL_API_KEY || '';
