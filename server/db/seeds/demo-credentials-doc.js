/**
 * Single source of truth for demo credential documentation.
 * Used by docs/e2e/uat-demo-personas.md and validated in server/test/seed.test.js.
 */
import { DEMO_PASSWORD, DEMO_USERS } from './demo-constants.js';

/** Stable key for the primary manual-test login (Frederique).
 *  Legacy wire name `alice` is retained so DEMO_IDS/DEMO_USERS keys stay stable across scenarios. */
export const MAIN_DEMO_USER_KEY = 'alice';

/** Ordered list for documentation tables — main user first. */
export const DEMO_USER_DOC_ORDER = [
  'alice',
  'bob',
  'carol',
  'eve',
  'dave',
  'grace',
];

export function buildDemoCredentialsTableRows() {
  return DEMO_USER_DOC_ORDER.map((key) => {
    const user = DEMO_USERS[key];
    if (!user) {
      throw new Error(`Missing DEMO_USERS.${key} for credentials doc`);
    }
    return {
      key,
      name: user.display_name,
      email: user.email,
      password: DEMO_PASSWORD,
      role: user.role_description,
      is_main: key === MAIN_DEMO_USER_KEY,
    };
  });
}

export function buildDemoCredentialsMarkdownTable() {
  const header = '| User | Email | Password | Role |';
  const separator = '|------|-------|----------|------|';
  const rows = buildDemoCredentialsTableRows().map(
    ({ name, email, password, role, is_main }) =>
      `| ${is_main ? `**${name}** (main)` : name} | \`${email}\` | \`${password}\` | ${role} |`,
  );
  return [header, separator, ...rows].join('\n');
}
