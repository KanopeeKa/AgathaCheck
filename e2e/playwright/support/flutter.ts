import type { Locator, Page } from '@playwright/test';
import { passHostingWaf } from './waf';

/** Wait until the Flutter web canvas is mounted. */
export async function waitForFlutter(page: Page): Promise<void> {
  await waitForFlutterRoute(page, '/landing');
}

/** Navigate to a Flutter route and enable the accessibility tree. */
export async function waitForFlutterRoute(page: Page, path: string): Promise<void> {
  if (path === '/landing' || path === '/') {
    await passHostingWaf(page);
  }
  await page.goto(path);
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

/** Re-enable semantics when Flutter collapses the tree after overlays (dropdowns, dialogs). */
export async function refreshFlutterAccessibility(page: Page): Promise<void> {
  await enableFlutterAccessibility(page);
  await page.waitForTimeout(300);
}

/** Escape user text for use inside RegExp. */
export function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

/**
 * Legacy pet list (`/`) or post-experience-split guardian shell (`/g/home`).
 * Prefer this over a single "To Do" button after the experience split.
 */
export function homeShellLocator(page: Page): Locator {
  return page
    .getByRole('button', { name: 'To Do' })
    .or(page.getByRole('button', { name: 'Add Pet' }))
    .or(page.getByText('No pets yet'))
    .or(page.getByRole('button', { name: 'Home' }))
    .or(page.getByRole('button', { name: 'Events' }));
}

/** Wait until the user has landed on a home surface after login or signup. */
export async function expectHomeShellVisible(
  page: Page,
  timeout = 60_000,
): Promise<void> {
  await dismissConsentBannerIfPresent(page);
  await refreshFlutterAccessibility(page);
  await homeShellLocator(page).first().waitFor({ timeout });
}

/** Flutter MergeSemantics nodes may surface as button or group depending on the widget. */
export function semanticsByName(page: Page, pattern: string | RegExp) {
  const name =
    typeof pattern === 'string' ? new RegExp(escapeRegExp(pattern), 'i') : pattern;
  return page
    .getByRole('button', { name })
    .or(page.getByRole('group', { name }))
    .first();
}

/** AppLogoTitle exposes a banner like "Go to home {title}" in Flutter semantics. */
export async function expectAppBarTitle(page: Page, title: string | RegExp): Promise<void> {
  const pattern =
    typeof title === 'string'
      ? new RegExp(title.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i')
      : title;
  await page.getByRole('banner', { name: pattern }).waitFor({ timeout: 30_000 });
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
 * Type into a Flutter web field so onChanged fires (fill() alone is unreliable).
 */
async function typeIntoField(
  field: import('@playwright/test').Locator,
  value: string,
): Promise<void> {
  const page = field.page();
  await field.click();
  await page.waitForTimeout(150);
  await field.press('Control+a');
  await page.keyboard.press('Backspace');
  await page.keyboard.type(value, { delay: 45 });
  await field.press('Tab');
  await page.waitForTimeout(150);
}

export async function fillTextbox(
  page: Page,
  name: string | RegExp,
  value: string,
): Promise<void> {
  const field = page.getByRole('textbox', { name, exact: typeof name === 'string' });
  await field.waitFor({ state: 'visible' });
  await typeIntoField(field, value);
}

async function fieldHasValue(
  field: import('@playwright/test').Locator,
  value: string,
): Promise<boolean> {
  try {
    return (await field.inputValue({ timeout: 2_000 })) === value;
  } catch {
    // Semantics-only fields hide inputValue; typeIntoField already used keyboard.type.
    return true;
  }
}

export async function fillLabelledField(
  page: Page,
  label: string,
  value: string,
): Promise<void> {
  const byRole = page
    .getByRole('textbox', { name: label, exact: false })
    .or(page.getByRole('textbox', { name: new RegExp(`^${escapeRegExp(label)}`, 'i') }));
  const roleCount = await byRole.count();
  for (let i = 0; i < roleCount; i++) {
    const field = byRole.nth(i);
    if (await field.isVisible()) {
      await typeIntoField(field, value);
      if (await fieldHasValue(field, value)) return;
    }
  }

  const ariaSelectors = [
    `input[aria-label="${label}"]`,
    `input[aria-label="${label} *"]`,
    `input[aria-label^="${label}"]`,
    `textarea[aria-label="${label}"]`,
    `textarea[aria-label="${label} *"]`,
    `textarea[aria-label^="${label}"]`,
  ];

  for (const selector of ariaSelectors) {
    const locator = page.locator(selector);
    const count = await locator.count();
    for (let i = 0; i < count; i++) {
      const field = locator.nth(i);
      if (await field.isVisible()) {
        await typeIntoField(field, value);
        if (await fieldHasValue(field, value)) return;
      }
    }
  }

  throw new Error(`Could not find visible field for label: ${label}`);
}

/** Open a Flutter dropdown and choose an option by visible label. */
export async function selectDropdownOption(
  page: Page,
  fieldLabel: string,
  optionLabel: string,
): Promise<void> {
  const labelVariants = [fieldLabel, fieldLabel.replace(/ \*$/, '')];

  for (const label of labelVariants) {
    const combobox = page.getByRole('combobox', { name: label, exact: false });
    if ((await combobox.count()) > 0) {
      await combobox.first().click();
      await page.getByRole('option', { name: optionLabel, exact: true }).click();
      await refreshFlutterAccessibility(page);
      return;
    }

    const button = page.getByRole('button', { name: label, exact: false });
    if ((await button.count()) > 0) {
      await button.first().click();
      await page
        .getByRole('menuitem', { name: optionLabel, exact: true })
        .or(page.getByRole('option', { name: optionLabel, exact: true }))
        .first()
        .click();
      await refreshFlutterAccessibility(page);
      return;
    }
  }

  throw new Error(`Could not find dropdown for label: ${fieldLabel}`);
}
