/**
 * Playwright specs for frozen Shelter/Fostering domains — excluded from Pre-UAT shards.
 * See docs/engineering/frozen-domains/manifest.json
 */
export const FROZEN_E2E_SPECS = new Set([
  'adoption.spec.ts',
  'experience.foster-portal.spec.ts',
  'foster.onboarding.spec.ts',
  'fostering.platform.spec.ts',
  'fostering.session-detail.spec.ts',
  'org.onboarding.spec.ts',
  'org.timeline.spec.ts',
  'organisation.admin-contacts.spec.ts',
  'organisation.connections.spec.ts',
  'organisation.customisations.spec.ts',
  'organisation.dashboard.spec.ts',
  'organisation.discovery.spec.ts',
  'organisation.edit.spec.ts',
  'organisation.management.spec.ts',
  'organisation.member.privacy.spec.ts',
  'organisation.permissions.spec.ts',
  'organisation.pet-filters.spec.ts',
  'organisation.pet.management.spec.ts',
  'organisation.profile.spec.ts',
  'organisation.redacted-pet.spec.ts',
  'organisation.sessions.spec.ts',
]);
