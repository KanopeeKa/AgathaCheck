import type { Page } from '@playwright/test';

/** Wait until the Flutter web canvas is mounted. */
export async function waitForFlutter(page: Page): Promise<void> {
  await page.goto('/landing');
  await page.waitForSelector('flutter-view, flt-glass-pane', { state: 'attached', timeout: 60_000 });
  await enableFlutterAccessibility(page);
  await dismissConsentBannerIfPresent(page);
  // Allow the first frame + Riverpod bootstrap.
  await page.waitForTimeout(750);
}

/**
 * Flutter web hides the semantics tree until the user opts in.
 * The placeholder button is positioned off-screen; click it via the DOM.
 */
export async function enableFlutterAccessibility(page: Page): Promise<void> {
  await page.evaluate(() => {
    const placeholder =
      document.querySelector('flt-semantics-placeholder') ??
      document.querySelector('flt-glass-pane')?.shadowRoot?.querySelector('flt-semantics-placeholder');
    if (placeholder instanceof HTMLElement) {
      placeholder.click();
    }
  });
  await page.waitForTimeout(500);
}

/** Dismiss the GDPR consent banner when shown (first visit). */
export async function dismissConsentBannerIfPresent(page: Page): Promise<void> {
  const accept = page.getByRole('button', { name: 'Accept All' });
  const count = await accept.count();
  for (let i = 0; i < count; i++) {
    const button = accept.nth(i);
    if (await button.isVisible().catch(() => false)) {
      await button.click();
      await page.waitForTimeout(300);
      return;
    }
  }
}

/**
 * Fill a labelled text field in the Flutter semantics tree.
 * Prefer aria-label inputs (reliable on Flutter web) over getByLabel, which can
 * match hidden browser autofill elements.
 */
async function typeIntoField(
  field: import('@playwright/test').Locator,
  value: string,
): Promise<void> {
  await field.click();
  await field.fill(value);
  if ((await field.inputValue()) !== value) {
    await field.fill('');
    await field.pressSequentially(value, { delay: 20 });
  }
}

export async function fillLabelledField(
  page: Page,
  label: string,
  value: string,
): Promise<void> {
  const ariaSelectors = [
    `input[aria-label="${label}"]`,
    `input[aria-label="${label} *"]`,
    `textarea[aria-label="${label}"]`,
    `textarea[aria-label="${label} *"]`,
  ];

  for (const selector of ariaSelectors) {
    const locator = page.locator(selector);
    const count = await locator.count();
    for (let i = 0; i < count; i++) {
      const field = locator.nth(i);
      if (await field.isVisible()) {
        await typeIntoField(field, value);
        return;
      }
    }
  }

  const byRole = page.getByRole('textbox', { name: label, exact: false });
  const roleCount = await byRole.count();
  for (let i = 0; i < roleCount; i++) {
    const field = byRole.nth(i);
    if (await field.isVisible()) {
      await typeIntoField(field, value);
      return;
    }
  }

  throw new Error(`Could not find visible field for label: ${label}`);
}
