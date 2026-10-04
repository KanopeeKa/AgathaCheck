/**
 * @bdd gdpr_data_rights.feature
 * Scenario: Exporting my personal data as JSON
 * Scenario: Deleting my account with password confirmation
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import {
  assertPreErasureTokenAccountUnavailable,
  createPet,
  exportUserData,
  pollErasureStatusCompleted,
  tryLogin,
} from '../support/api';
import { expectHomeShellHidden, refreshFlutterAccessibility } from '../support/flutter';
import { MyDetailsPage } from '../pages/my-details.page';

test.describe('GDPR data rights', () => {
  test('exporting my personal data as JSON', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await createPet(baseURL, testUser.accessToken, 'Bella', 'Dog');

    const petList = await loginAs(page, testUser);
    await petList.expectLoaded();

    const myDetails = new MyDetailsPage(page);
    await myDetails.openFromUserMenu();
    await myDetails.exportMyData();

    const exportPayload = await exportUserData(baseURL, testUser.accessToken);
    expect(exportPayload.user.id).toBe(testUser.userId);
    expect(exportPayload.user.email).toBe(testUser.email);
    expect(exportPayload.exported_at).toBeTruthy();
    expect(exportPayload.pets.some((p) => p.name === 'Bella')).toBeTruthy();
  });

  test('deleting my account with password confirmation', async ({ page, testUser }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const petList = await loginAs(page, testUser);
    await petList.expectLoaded();

    const myDetails = new MyDetailsPage(page);
    await myDetails.openFromUserMenu();

    const deleteResponsePromise = page.waitForResponse(
      (response) =>
        response.request().method() === 'DELETE' &&
        /\/auth\/me$/.test(response.url()) &&
        response.status() < 400,
    );

    await myDetails.deleteAccount(testUser.password);

    const deleteResponse = await deleteResponsePromise;
    const deleteBody = (await deleteResponse.json()) as {
      message: string;
      erasure?: { operation_id: string; status_token?: string };
    };
    expect(deleteBody.message).toBeTruthy();
    expect(deleteBody.erasure?.operation_id).toBeTruthy();
    expect(deleteBody.erasure?.status_token).toBeTruthy();

    await refreshFlutterAccessibility(page);
    await expect(
      page.getByText(
        /account has been deleted.*still being removed|compte a été supprimé.*encore en cours de suppression/i,
      ),
    ).toBeVisible({ timeout: 30_000 });
    await expect(page.getByRole('button', { name: 'Sign In', exact: true })).toBeVisible();
    await expectHomeShellHidden(page);

    const loginAttempt = await tryLogin(baseURL, testUser.email, testUser.password);
    expect(loginAttempt.ok).toBe(false);
    expect(loginAttempt.status).toBeGreaterThanOrEqual(400);

    await assertPreErasureTokenAccountUnavailable(baseURL, testUser.accessToken);

    await pollErasureStatusCompleted(
      baseURL,
      deleteBody.erasure!.operation_id,
      deleteBody.erasure!.status_token!,
    );
  });
});
