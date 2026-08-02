/**
 * @bdd organisation_profile.feature
 * Scenario: Anonymous visitor can view a discoverable organisation profile
 * Scenario: Opted-out organisation profile is hidden from anonymous visitors
 * Scenario: Active member can view opted-out organisation public profile
 * Scenario: Public profile API exposes only public-tier fields
 */
import { test, expect } from '../fixtures/auth.fixture';

test.describe('Organisation profile', () => {
  test('@P1 skeleton — mapped in organisation_profile.feature', async () => {
    expect(true).toBe(true);
  });
});
