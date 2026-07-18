import type { Locator, Page } from '@playwright/test';
import { passHostingWaf } from './waf';
import { isLiveHostingTarget } from './hosting';

function postLoginTimeout(fallback = 60_000): number {
  return isLiveHostingTarget() ? 120_000 : fallback;
}

/** Effective Flutter route path (hash routes win over pathname on Flutter web). */
export function flutterRoutePath(url: string): string {
  const parsed = new URL(url);
  if (parsed.hash.startsWith('#/')) {
    return parsed.hash.slice(1).split('?')[0];
  }
  return parsed.pathname;
}

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
  timeout?: number,
): Promise<void> {
  const effectiveTimeout = timeout ?? postLoginTimeout(60_000);
  await dismissConsentBannerIfPresent(page);
  await refreshFlutterAccessibility(page);
  await homeShellLocator(page).first().waitFor({ timeout: effectiveTimeout });
}

/** Assert no home shell chrome is visible (e.g. still on landing after failed login). */
export async function expectHomeShellHidden(
  page: Page,
  timeout = 15_000,
): Promise<void> {
  const { expect } = await import('@playwright/test');
  await expect(async () => {
    await refreshFlutterAccessibility(page);
    const matches = await homeShellLocator(page).all();
    for (const match of matches) {
      if (await match.isVisible()) {
        throw new Error('Home shell chrome is still visible');
      }
    }
  }).toPass({ timeout });
}

export type ExperienceChoice = 'guardian' | 'organization';

/** Complete the post-login experience chooser when dual-role users land on `/app/choose`. */
export async function completeExperienceChooserIfPresent(
  page: Page,
  choice: ExperienceChoice = 'guardian',
  timeout?: number,
): Promise<void> {
  const effectiveTimeout = timeout ?? postLoginTimeout(30_000);
  await dismissConsentBannerIfPresent(page);
  await refreshFlutterAccessibility(page);

  const chooserHeading = page.getByText(/How will you use Agatha Track/i);
  const onChooserUrl = /\/app\/choose/.test(page.url());
  const chooserVisible = onChooserUrl
    || (await chooserHeading.isVisible({ timeout: 3_000 }).catch(() => false));
  if (!chooserVisible) return;

  if (choice === 'guardian') {
    await page.getByText('Individual Pet Guardian').click();
  } else {
    await page.getByText('Shelter / Organisation').click();
  }
  await page.getByRole('button', { name: 'Continue' }).click();
  const homePattern =
    choice === 'guardian'
      ? /\/g\/(home|onboarding)/
      : /\/o\/(home|onboarding)/;
  await page.waitForURL(homePattern, { timeout: effectiveTimeout });
  if (choice === 'guardian' && /\/g\/onboarding/.test(page.url())) {
    await skipGuardianOnboardingIfPresent(page, effectiveTimeout);
  }
  if (choice === 'organization' && /\/o\/onboarding/.test(page.url())) {
    await skipOrgOnboardingIfPresent(page, effectiveTimeout);
  }
  await refreshFlutterAccessibility(page);
}

/** Wait until post-login routing settles on a home surface or the experience chooser. */
export async function waitForPostLoginRoute(page: Page, timeout?: number): Promise<void> {
  const effectiveTimeout = timeout ?? postLoginTimeout();
  const { expect } = await import('@playwright/test');

  await expect(async () => {
    await dismissConsentBannerIfPresent(page);
    await refreshFlutterAccessibility(page);

    const path = flutterRoutePath(page.url());
    if (/\/(g|o)\/home/.test(path) || path === '/app/choose' || path === '/g/onboarding' || path === '/o/onboarding') {
      return;
    }

    if (await page.getByText(/How will you use Agatha Track/i).isVisible({ timeout: 1_000 }).catch(() => false)) {
      return;
    }

    if (await isExperienceShellVisible(page)) {
      return;
    }

    if (await page.getByRole('button', { name: 'To Do' }).isVisible({ timeout: 1_000 }).catch(() => false)) {
      return;
    }

    throw new Error(`Post-login route not ready (url=${page.url()})`);
  }).toPass({ timeout: effectiveTimeout });
}

/** Skip the org super-admin onboarding wizard when shown. */
export async function skipOrgOnboardingIfPresent(
  page: Page,
  timeout?: number,
): Promise<void> {
  const effectiveTimeout = timeout ?? postLoginTimeout(30_000);
  await dismissConsentBannerIfPresent(page);
  await refreshFlutterAccessibility(page);

  const onOnboardingUrl = /\/o\/onboarding/.test(page.url());
  const skipButton = page.getByRole('button', { name: /skip for now/i });
  const skipVisible = onOnboardingUrl
    || (await skipButton.isVisible({ timeout: 3_000 }).catch(() => false));
  if (!skipVisible) return;

  await skipButton.click();
  await page.waitForURL(/\/o\/home/, { timeout: effectiveTimeout });
  await refreshFlutterAccessibility(page);
}

/** Complete the org super-admin onboarding wizard (inventory pet + reminder). */
export async function completeOrgOnboarding(
  page: Page,
  petName: string,
  reminderName: string,
  timeout?: number,
): Promise<void> {
  const effectiveTimeout = timeout ?? postLoginTimeout(60_000);
  await page.waitForURL(/\/o\/onboarding/, { timeout: effectiveTimeout });
  await refreshFlutterAccessibility(page);

  await page.getByRole('button', { name: /get started/i }).click();
  const orgNameField = page.getByRole('textbox', { name: /organization name/i });
  if (await orgNameField.isVisible({ timeout: 2_000 }).catch(() => false)) {
    await fillLabelledField(page, 'Organization Name', 'Rescue Hearts');
    await page.getByRole('button', { name: 'Continue' }).click();
  }
  await fillLabelledField(page, 'Name', petName);
  await page.getByRole('button', { name: 'Continue' }).click();
  await fillLabelledField(page, 'Reminder name', reminderName);
  await page.getByRole('button', { name: /finish setup/i }).click();
  await page.waitForURL(/\/o\/home/, { timeout: effectiveTimeout });
  await refreshFlutterAccessibility(page);
}

/** Skip the guardian onboarding wizard when shown (fresh users with no pets). */
export async function skipGuardianOnboardingIfPresent(
  page: Page,
  timeout?: number,
): Promise<void> {
  const effectiveTimeout = timeout ?? postLoginTimeout(30_000);
  await dismissConsentBannerIfPresent(page);
  await refreshFlutterAccessibility(page);

  const onOnboardingUrl = /\/g\/onboarding/.test(page.url());
  const skipButton = page.getByRole('button', { name: /skip for now/i });
  const skipVisible = onOnboardingUrl
    || (await skipButton.isVisible({ timeout: 3_000 }).catch(() => false));
  if (!skipVisible) return;

  await skipButton.click();
  await page.waitForURL(/\/g\/home/, { timeout: effectiveTimeout });
  await refreshFlutterAccessibility(page);
}

/** Complete the guardian onboarding wizard (pet + reminder). */
export async function completeGuardianOnboarding(
  page: Page,
  petName: string,
  reminderName: string,
  timeout?: number,
): Promise<void> {
  const effectiveTimeout = timeout ?? postLoginTimeout(60_000);
  await page.waitForURL(/\/g\/onboarding/, { timeout: effectiveTimeout });
  await refreshFlutterAccessibility(page);

  await page.getByRole('button', { name: /get started/i }).click();
  await fillLabelledField(page, 'Name', petName);
  await page.getByRole('button', { name: 'Continue' }).click();
  await fillLabelledField(page, 'Reminder name', reminderName);
  await page.getByRole('button', { name: /finish setup/i }).click();
  await page.waitForURL(/\/g\/home/, { timeout: effectiveTimeout });
  await refreshFlutterAccessibility(page);
}

/** After login/signup submit: wait for routing, complete chooser if needed, assert home shell. */
export async function reachAuthenticatedHome(
  page: Page,
  options: { experience?: ExperienceChoice; timeout?: number } = {},
): Promise<void> {
  const timeout = options.timeout ?? postLoginTimeout();
  await waitForPostLoginRoute(page, timeout);
  await completeExperienceChooserIfPresent(page, options.experience ?? 'guardian', timeout);
  await skipGuardianOnboardingIfPresent(page, timeout);
  await skipOrgOnboardingIfPresent(page, timeout);
  await expectHomeShellVisible(page, timeout);
}

/** True when the post-split experience shell (`/g/home` or `/o/home`) is visible. */
export async function isExperienceShellVisible(page: Page): Promise<boolean> {
  const homeNav = page.getByRole('button', { name: 'Home' });
  return homeNav.isVisible({ timeout: 3_000 }).catch(() => false);
}

/** Open the experience shell drawer (hamburger menu). */
export async function openExperienceDrawer(page: Page): Promise<void> {
  await dismissConsentBannerIfPresent(page);
  await refreshFlutterAccessibility(page);
  await page.getByRole('button', { name: 'Settings' }).click();
  await page.waitForTimeout(400);
  await refreshFlutterAccessibility(page);
}

/** Log out via legacy user menu or experience shell drawer. */
export async function logOutFromApp(page: Page): Promise<void> {
  await dismissConsentBannerIfPresent(page);
  const legacyMenu = page.getByRole('button', { name: /user menu|menu utilisateur/i });
  if (await legacyMenu.isVisible({ timeout: 2_000 }).catch(() => false)) {
    await legacyMenu.click();
    await page.waitForTimeout(500);
    await page
      .getByRole('menuitem', { name: /log.out|déconnexion/i })
      .or(page.getByText('Log Out', { exact: true }))
      .first()
      .click();
    return;
  }

  if (await isExperienceShellVisible(page)) {
    await openExperienceDrawer(page);
    await page
      .getByText('Log Out', { exact: true })
      .or(page.getByText('Déconnexion', { exact: true }))
      .first()
      .click();
    return;
  }

  throw new Error('Could not find a logout entry point');
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
