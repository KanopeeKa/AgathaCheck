/**
 * @bdd fostering_sessions.feature
 * Scenario: Admin can open the fostering sessions list from the profile
 * Scenario: Sessions list highlights nearly finished placements
 * Scenario: Admin can message a foster from the sessions list
 */
import { test, expect } from '../fixtures/auth.fixture';
import {
  acceptFosterPlacement,
  createFosterPlacement,
  createOrgPet,
  getOrgPlacements,
  seedRescueHearts,
} from '../support/api';

function isoDay(offsetDays: number): string {
  const date = new Date();
  date.setUTCDate(date.getUTCDate() + offsetDays);
  return date.toISOString().slice(0, 10);
}

async function seedRescueHeartsWithSession(
  baseURL: string,
  options: { endDate?: string } = {},
) {
  const { alice, eve, org } = await seedRescueHearts(baseURL);
  const pet = await createOrgPet(baseURL, alice.accessToken, org.id, {
    name: 'Buddy',
    species: 'dog',
  });
  const placement = await createFosterPlacement(
    baseURL,
    alice.accessToken,
    org.id,
    pet.id,
    eve.userId,
    {
      startDate: isoDay(-20),
      endDate: options.endDate ?? isoDay(30),
    },
  );
  await acceptFosterPlacement(baseURL, eve.accessToken, placement.id);
  return { alice, jane: eve, org, pet, placement };
}

test.describe('Fostering sessions list', () => {
  test('@P1 admin can load fostering sessions list with pet and foster names', async () => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const { alice, org } = await seedRescueHeartsWithSession(baseURL);

    const sessions = await getOrgPlacements(baseURL, alice.accessToken, org.id);
    expect(sessions.length).toBeGreaterThanOrEqual(1);
    const row = sessions.find((item) => item.pet_name === 'Buddy');
    expect(row).toBeTruthy();
    expect(row?.foster_name).toContain('Eve');
  });

  test('@P1 sessions list highlights nearly finished placements', async () => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const { alice, org } = await seedRescueHeartsWithSession(baseURL, {
      endDate: isoDay(5),
    });

    const sessions = await getOrgPlacements(baseURL, alice.accessToken, org.id, {
      derived_status: 'nearly_finished',
    });
    expect(sessions.length).toBeGreaterThanOrEqual(1);
    const row = sessions.find((item) => item.pet_name === 'Buddy');
    expect(row?.derived_status).toBe('nearly_finished');
    expect(row?.nearly_finished).toBe(true);
  });

  test('@P1 admin sees foster email for mailto affordance on sessions list', async () => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const { alice, jane, org } = await seedRescueHeartsWithSession(baseURL);

    const sessions = await getOrgPlacements(baseURL, alice.accessToken, org.id);
    const row = sessions.find((item) => item.pet_name === 'Buddy');
    expect(row).toBeTruthy();
    expect(row?.foster_email).toBe(jane.email);
  });
});
