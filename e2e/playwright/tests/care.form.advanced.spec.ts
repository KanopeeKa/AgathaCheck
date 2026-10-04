/**
 * @bdd care_form_advanced.feature
 * Scenario: F42 expand Advanced and choose Fixed schedule
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import { HealthEntryFormPage } from '../pages/health-entry-form.page';
import { createPet } from '../support/api';
import { enableFlutterAccessibility } from '../support/flutter';

test.describe('Care form Advanced settings (F42)', () => {
  test('expand Advanced and choose Fixed schedule', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'Milo');

    await loginAs(page, testUser, { experience: 'guardian' });
    await enableFlutterAccessibility(page);
    await page.goto(`${baseURL}/pet/${pet.id}/care/add`);
    await page.waitForLoadState('networkidle');

    const form = new HealthEntryFormPage(page);
    await form.expectLoaded();
    await form.selectCareFamily('Medication');
    await form.expandAdvancedSettings();
    await form.selectScheduleType('Fixed schedule');
    await form.expectScheduleTypeSelected('Fixed schedule');
  });
});
