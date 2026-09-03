import type { Locator, Page } from '@playwright/test';
import { isLiveHostingTarget, isLiveUatTarget } from './hosting';
import { passHostingWaf } from './waf';

/** Welcome title on FTUE chooser and guardian onboarding (`AgathaTrack` on wire). */
export const welcomeAgathaTrackText =
  /Welcome to Agatha\s*Track|Bienvenue sur Agatha\s*Track/i;

function postLoginTimeout(fallback = 60_000): number {
  // Longer timeouts on any live host (UAT or prod).
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

/** Test [path] against [pattern] safely inside retry loops (reset global/sticky lastIndex). */
function matchesFlutterRoute(path: string, pattern: RegExp): boolean {
  if (pattern.global || pattern.sticky) {
    pattern.lastIndex = 0;
  }
  return pattern.test(path);
}

/**
 * Poll until the effective Flutter route matches.
 * Prefer over `page.waitForURL` — hash SPA navigations do not fire `load`.
 */
export async function waitForFlutterRoutePattern(
  page: Page,
  pattern: RegExp,
  timeout?: number,
): Promise<void> {
  const effectiveTimeout = timeout ?? postLoginTimeout(30_000);
  const { expect } = await import('@playwright/test');
  await expect(async () => {
    const path = flutterRoutePath(page.url());
    if (!matchesFlutterRoute(path, pattern)) {
      throw new Error(`Route ${path} does not match ${pattern} (url=${page.url()})`);
    }
  }).toPass({ timeout: effectiveTimeout });
}

export type ShellFallbackContext = {
  helper: string;
  testTitle: string | null;
  locale?: string | null;
};

/**
 * Last-resort navigation when shell detection or drawer clicks fail.
 * Emits `E2E_NAV_FALLBACK` with a fixed JSON payload for CI log aggregation.
 */
export async function navigateWithShellFallback(
  page: Page,
  targetRoutePattern: RegExp,
  directHashRoute: string,
  readyFn: () => Promise<void>,
  context: ShellFallbackContext,
  timeout = 30_000,
): Promise<void> {
  const payload = {
    helper: context.helper,
    fromURL: page.url(),
    toRoute: directHashRoute,
    locale: context.locale ?? null,
    testTitle: context.testTitle,
  };
  console.warn('E2E_NAV_FALLBACK', JSON.stringify(payload));

  await page.goto(flutterGotoUrl(directHashRoute));
  await refreshFlutterAccessibility(page);
  await waitForFlutterRoutePattern(page, targetRoutePattern, timeout);
  await readyFn();
}

/** Build a URL that reaches a Flutter hash route on web. */
export function flutterGotoUrl(path: string): string {
  if (path === '/landing' || path === '/' || path === '') return '/landing';
  const normalized = path.startsWith('/') ? path : `/${path}`;
  return `/landing#${normalized}`;
}

/** Wait until the Flutter web canvas is mounted. */
export async function waitForFlutter(page: Page): Promise<void> {
  await waitForFlutterRoute(page, '/landing');
}

/** Navigate to a Flutter route and enable the accessibility tree. */
export async function waitForFlutterRoute(page: Page, path: string): Promise<void> {
  if (path === '/landing' || path === '/') {
    // Live UAT gate (warmup-uat + storageState when E2E_TLS_INSECURE=1) skips redundant WAF here.
    // Other live UAT runs without the gate still need passHostingWaf before landing nav.
    const liveUatGate = isLiveUatTarget() && process.env.E2E_TLS_INSECURE === '1';
    if (!liveUatGate && isLiveUatTarget()) {
      await passHostingWaf(page);
    }
  }
  await page.goto(flutterGotoUrl(path));
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
 * Post-login shell indicators: experience bell + section drawer, guardian dashboard sections,
 * empty-state, or legacy nav chrome (Home / Settings / To Do).
 * Navigation reversal (phase-1-navigation.md): Home removed; hamburger tooltip is "Open menu".
 * Add Pet FAB moved to `/pc/pets` (guardian UI rework #407).
 */
export function homeShellLocator(page: Page): Locator {
  return page
    .getByRole('button', { name: /open notifications/i })
    .or(page.getByRole('button', { name: /open menu/i }))
    .or(page.getByRole('button', { name: 'To Do' }))
    .or(page.getByRole('group', { name: DASHBOARD_SECTION_NAMES.myPets }))
    .or(page.getByText('No pets yet'))
    .or(page.getByRole('button', { name: /^(Home|Accueil)$/i }))
    .or(page.getByRole('button', { name: /^(Settings|Paramètres)/i }));
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

/**
 * Wait for home after mutations that `context.go('/')` (delete pet, mark passed away).
 * Flutter redirects `/` → `/app/resolve` → `/pc/home`, `/o/home`, or `/app/choose` when
 * the account has no pets left.
 */
export async function waitForHomeAfterMutation(
  page: Page,
  timeout?: number,
): Promise<void> {
  const effectiveTimeout = timeout ?? postLoginTimeout(30_000);
  await waitForFlutterRoutePattern(
    page,
    /\/(pc|o)\/(home|onboarding)|\/app\/(resolve|choose)/,
    effectiveTimeout,
  );
  await completeExperienceChooserIfPresent(page, 'guardian', effectiveTimeout);
  await waitForFlutterRoutePattern(page, /\/(pc|o)\/(home|onboarding)/, effectiveTimeout);
  await skipGuardianOnboardingIfPresent(page, effectiveTimeout);
  await skipOrgOnboardingIfPresent(page, effectiveTimeout);
  await waitForFlutterRoutePattern(page, /\/(pc|o)\/home/, effectiveTimeout);
  await expectHomeShellVisible(page, effectiveTimeout);
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

/** Complete the post-login FTUE when empty accounts land on `/app/choose`. */
export async function completeExperienceChooserIfPresent(
  page: Page,
  choice: ExperienceChoice = 'guardian',
  timeout?: number,
  options: { skipGuardianOnboarding?: boolean } = {},
): Promise<void> {
  const skipGuardianOnboarding = options.skipGuardianOnboarding ?? true;
  const effectiveTimeout = timeout ?? postLoginTimeout(30_000);
  await dismissConsentBannerIfPresent(page);
  await refreshFlutterAccessibility(page);

  const path = flutterRoutePath(page.url());
  // Onboarding wizards reuse the FTUE welcome title — not the experience chooser.
  if (path === '/pc/onboarding' || path === '/o/onboarding') return;

  const ftueTrackPets = page
    .locator('[flt-semantics-identifier="ftue_action_track_pets"]')
    .or(page.getByRole('button', { name: /Track my pets|Suivre mes animaux/i }));
  const ftueRunShelter = page
    .locator('[flt-semantics-identifier="ftue_action_run_shelter"]')
    .or(page.getByRole('button', { name: /Run a shelter|Gérer un refuge/i }));
  const onChooserUrl = path === '/app/choose';
  const waitChooserButton = (target: ReturnType<Page['locator']>) =>
    target
      .first()
      .waitFor({ state: 'visible', timeout: 3_000 })
      .then(() => true)
      .catch(() => false);
  const chooserVisible =
    onChooserUrl ||
    (await waitChooserButton(ftueTrackPets)) ||
    (await waitChooserButton(ftueRunShelter));
  if (!chooserVisible) return;

  await refreshFlutterAccessibility(page);

  const clickFtueAction = async (identifier: string, label: RegExp) => {
    const card = page.locator(`[flt-semantics-identifier="${identifier}"]`);
    const byLabel = page.getByRole('button', { name: label });
    const target = card.or(byLabel).first();
    const visible = await target
      .waitFor({ state: 'visible', timeout: 15_000 })
      .then(() => true)
      .catch(() => false);
    if (!visible && flutterRoutePath(page.url()) === '/app/choose') {
      await page.goto(flutterGotoUrl('/app/resolve'));
      await page.waitForTimeout(1_500);
      await refreshFlutterAccessibility(page);
      if (flutterRoutePath(page.url()) !== '/app/choose') return;
    }
    await target.click({ timeout: effectiveTimeout });
  };

  if (choice === 'guardian') {
    await clickFtueAction('ftue_action_track_pets', /Track my pets|Suivre mes animaux/i);
  } else {
    await clickFtueAction('ftue_action_run_shelter', /Run a shelter|Gérer un refuge/i);
  }
  const homePattern =
    choice === 'guardian'
      ? /\/pc\/(home|onboarding)/
      : /\/o\/(home|onboarding)/;
  await waitForFlutterRoutePattern(page, homePattern, effectiveTimeout);
  const route = flutterRoutePath(page.url());
  if (choice === 'guardian' && route === '/pc/onboarding' && skipGuardianOnboarding) {
    await skipGuardianOnboardingIfPresent(page, effectiveTimeout);
  }
  if (choice === 'organization' && route === '/o/onboarding') {
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
    if (
      /\/(pc|o)\/home/.test(path) ||
      path === '/app/choose' ||
      path === '/pc/onboarding' ||
      path === '/o/onboarding'
    ) {
      return;
    }

    if (await page.getByText(welcomeAgathaTrackText).isVisible({ timeout: 1_000 }).catch(() => false)) {
      return;
    }

    if (await isExperienceShellVisible(page)) {
      return;
    }

    if (await page.getByRole('button', { name: 'To Do' }).isVisible({ timeout: 1_000 }).catch(() => false)) {
      return;
    }

    // If an auth token is already in localStorage but Flutter is still showing /landing,
    // the GoRouter redirect hasn't fired yet (race on slow live UAT cold-start).
    // Navigate directly to /app/resolve to kick-start post-login routing.
    if (path === '/landing') {
      const hasAuthToken = await page
        .evaluate(() =>
          Object.keys(localStorage).some(
            (k) => k.includes('auth_access_token') && !!localStorage.getItem(k),
          ),
        )
        .catch(() => false);
      if (hasAuthToken) {
        await page.goto(flutterGotoUrl('/app/resolve'));
        await page.waitForTimeout(1_500);
        await refreshFlutterAccessibility(page);
      }
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

  if (flutterRoutePath(page.url()) !== '/o/onboarding') return;

  const skipButton = page.getByRole('button', { name: /skip for now/i });
  if (!(await skipButton.isVisible({ timeout: 3_000 }).catch(() => false))) return;

  await skipButton.click();
  await waitForFlutterRoutePattern(page, /\/o\/home/, effectiveTimeout);
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
  await waitForFlutterRoutePattern(page, /\/o\/onboarding/, effectiveTimeout);
  await refreshFlutterAccessibility(page);

  await page.getByRole('button', { name: /get started/i }).click();
  await refreshFlutterAccessibility(page);
  const orgNameField = page.getByRole('textbox', { name: /organization name/i });
  if (await orgNameField.isVisible({ timeout: 2_000 }).catch(() => false)) {
    await fillLabelledField(page, 'Organisation Name', 'Rescue Hearts');
    await page.getByRole('button', { name: 'Continue' }).click();
    await refreshFlutterAccessibility(page);
  }
  await page.getByRole('textbox', { name: /name/i }).first().waitFor({ timeout: effectiveTimeout });
  await fillLabelledField(page, 'Name', petName);
  await page.getByRole('button', { name: 'Continue' }).click();
  await refreshFlutterAccessibility(page);
  await page.getByRole('textbox', { name: /reminder name/i }).waitFor({ timeout: effectiveTimeout });
  await fillLabelledField(page, 'Reminder name', reminderName);
  await page.getByRole('button', { name: /finish setup/i }).click();
  await waitForFlutterRoutePattern(page, /\/o\/home/, effectiveTimeout);
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

  if (flutterRoutePath(page.url()) !== '/pc/onboarding') return;

  const skipButton = page.getByRole('button', { name: /skip for now/i });
  if (!(await skipButton.isVisible({ timeout: 3_000 }).catch(() => false))) return;

  await skipButton.click();
  await waitForFlutterRoutePattern(page, /\/pc\/home/, effectiveTimeout);
  await refreshFlutterAccessibility(page);
}

/** Complete the guardian onboarding wizard (pet only). */
export async function completeGuardianOnboarding(
  page: Page,
  petName: string,
  timeout?: number,
): Promise<void> {
  const effectiveTimeout = timeout ?? postLoginTimeout(60_000);
  await waitForFlutterRoutePattern(page, /\/pc\/onboarding/, effectiveTimeout);
  await refreshFlutterAccessibility(page);

  await page.getByRole('button', { name: /get started|commencer/i }).click();
  await refreshFlutterAccessibility(page);
  await page
    .getByRole('textbox', { name: /name|nom/i })
    .first()
    .waitFor({ timeout: effectiveTimeout });
  await fillTextbox(page, /name|nom/i, petName);
  await page
    .getByRole('button', { name: /finish setup|terminer la configuration/i })
    .click();
  await waitForFlutterRoutePattern(page, /\/pc\/home/, effectiveTimeout);
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

/**
 * Top-nav controls for the experience shell (EN + FR).
 * Section roots: bell + workspace toggle (D-v4-3). Legacy hosts may still expose a hamburger.
 */
export function experienceShellNavLocator(page: Page): Locator {
  return page
    .getByRole('button', { name: /open notifications/i })
    .or(page.getByRole('button', { name: /Choose your workspace|Choisir votre espace/i }))
    .or(page.getByRole('button', { name: /open menu/i }))
    .or(page.getByRole('button', { name: /^(Home|Accueil)$/i }))
    .or(page.getByRole('button', { name: /^(Settings|Paramètres)/i }));
}

/** Workspace switcher on section roots (D-v4-3). */
export function workspaceToggleLocator(page: Page): Locator {
  return page
    .getByRole('button', {
      name: /Choose your workspace|Choisir votre espace de travail/i,
    })
    .or(page.getByRole('button', { name: /^Pet Care$|^Suivi$/i }))
    .or(page.getByRole('button', { name: /^Shelter$|^Refuge$/i }))
    .first();
}

/** Guardian bottom nav Account tab when compact shell is active (D-v4-2). */
export function guardianAccountTabLocator(page: Page): Locator {
  return page
    .getByRole('button', { name: /^Account$|^Compte$/i })
    .or(page.getByRole('tab', { name: /^Account$|^Compte$/i }))
    .first();
}

export async function isGuardianBottomNavVisible(page: Page): Promise<boolean> {
  return page
    .locator('[flt-semantics-identifier="guardian_bottom_navigation"]')
    .or(page.getByRole('button', { name: /^Dashboard$|^Tableau de bord$/i }))
    .first()
    .isVisible({ timeout: 2_000 })
    .catch(() => false);
}

async function openExperienceDrawerViaEdgeSwipe(page: Page): Promise<void> {
  const viewport = page.viewportSize() ?? { width: 1280, height: 720 };
  const y = Math.floor(viewport.height / 2);
  await page.mouse.move(8, y);
  await page.mouse.down();
  await page.mouse.move(Math.min(viewport.width * 0.45, 240), y, { steps: 12 });
  await page.mouse.up();
  await page.waitForTimeout(500);
  await refreshFlutterAccessibility(page);
}

/** True when the post-split experience shell (`/pc/home` or `/o/home`) is visible. */
export async function isExperienceShellVisible(page: Page): Promise<boolean> {
  return experienceShellNavLocator(page)
    .first()
    .isVisible({ timeout: 3_000 })
    .catch(() => false);
}

/** Open the experience shell drawer (hamburger or edge swipe when hamburger is hidden). */
export async function openExperienceDrawer(page: Page): Promise<void> {
  await dismissConsentBannerIfPresent(page);
  await refreshFlutterAccessibility(page);
  const menuButton = page
    .getByRole('button', { name: /open menu/i })
    .or(page.getByRole('button', { name: /^(Settings|Paramètres)/i }))
    .or(page.getByRole('button', { name: /menu/i }))
    .first();
  if (await menuButton.isVisible({ timeout: 2_000 }).catch(() => false)) {
    await menuButton.click({ timeout: 10_000 });
  } else {
    await openExperienceDrawerViaEdgeSwipe(page);
  }
  await page.waitForTimeout(400);
  await refreshFlutterAccessibility(page);
}

/** Navigate to `/account` via bottom nav (compact) or drawer (transitional D-v4-2). */
export async function openAccountFromShell(page: Page): Promise<void> {
  await dismissConsentBannerIfPresent(page);
  await refreshFlutterAccessibility(page);

  const accountTab = guardianAccountTabLocator(page);
  if (
    (await isGuardianBottomNavVisible(page)) &&
    (await accountTab.isVisible({ timeout: 2_000 }).catch(() => false))
  ) {
    await accountTab.click({ timeout: 10_000 });
    await waitForFlutterRoutePattern(page, /\/account(?:\?|$)/, 30_000);
    await refreshFlutterAccessibility(page);
    return;
  }

  const menuButton = page.getByRole('button', { name: /open menu/i }).first();
  if (await menuButton.isVisible({ timeout: 1_000 }).catch(() => false)) {
    await openExperienceDrawer(page);
    const accountEntry = page
      .getByRole('button', { name: /^account$/i })
      .or(page.locator('[flt-semantics-identifier="drawer_account"]'))
      .or(page.getByText('Account', { exact: true }))
      .or(page.getByText('Compte', { exact: true }))
      .first();
    await accountEntry.click({ timeout: 10_000 });
    await waitForFlutterRoutePattern(page, /\/account(?:\?|$)/, 30_000);
    await refreshFlutterAccessibility(page);
    return;
  }

  await navigateWithShellFallback(
    page,
    /\/account(?:\?|$)/,
    '/account',
    async () => undefined,
    { helper: 'openAccountFromShell', testTitle: null },
  );
}

/** @deprecated Prefer `openAccountFromShell` — kept for legacy call sites. */
export async function openAccountFromDrawer(page: Page): Promise<void> {
  await openAccountFromShell(page);
}

/** Log out via legacy user menu or Account screen (experience shell). */
export async function logOutFromApp(page: Page): Promise<void> {
  await dismissConsentBannerIfPresent(page);
  await refreshFlutterAccessibility(page);

  const clickLogoutEntry = async (): Promise<boolean> => {
    await refreshFlutterAccessibility(page);
    const entry = page
      .getByRole('button', { name: /log out|déconnexion/i })
      .or(page.getByRole('menuitem', { name: /log out|déconnexion/i }))
      .or(page.getByText('Log Out', { exact: true }))
      .or(page.getByText('Déconnexion', { exact: true }))
      .first();
    if (await entry.isVisible({ timeout: 3_000 }).catch(() => false)) {
      await entry.click();
      return true;
    }
    const forced = page.locator('text=/^Log Out$/i').first();
    if (await forced.count()) {
      await forced.click({ force: true });
      return true;
    }
    return false;
  };

  const legacyMenu = page.getByRole('button', { name: /user menu|menu utilisateur/i });
  if (await legacyMenu.isVisible({ timeout: 2_000 }).catch(() => false)) {
    await legacyMenu.click();
    await page.waitForTimeout(500);
    if (await clickLogoutEntry()) return;
  }

  if (await clickLogoutEntry()) return;

  const currentPath = flutterRoutePath(page.url());
  if (currentPath !== '/account') {
    // Direct hash-route navigation — same pattern as MyDetailsPage.openFromUserMenu.
    // Drawer Account is bottom-pinned and often off-screen in Playwright semantics.
    await page.goto(flutterGotoUrl('/account'));
    await refreshFlutterAccessibility(page);
    await waitForFlutterRoutePattern(page, /\/account(?:\?|$)/, 30_000);
  }

  if (await clickLogoutEntry()) return;

  const path = flutterRoutePath(page.url());
  if (path === '/landing' || path === '/') {
    return;
  }

  throw new Error('Could not find a logout entry point');
}

/** Guardian dashboard [DashboardSection] titles are semantics group labels, not plain text. */
export const DASHBOARD_SECTION_NAMES = {
  myPets: /My Pets|Mes animaux/i,
  dueAndOverdue: /CARE ACTIONS|SOINS/i,
  myVets: /Care team|CARE TEAM|Équipe de soins|ÉQUIPE DE SOINS/i,
} as const;

export function dashboardSectionGroup(
  page: Page,
  section: keyof typeof DASHBOARD_SECTION_NAMES | RegExp | string,
): Locator {
  const name =
    typeof section === 'string' &&
    Object.prototype.hasOwnProperty.call(DASHBOARD_SECTION_NAMES, section)
      ? DASHBOARD_SECTION_NAMES[section as keyof typeof DASHBOARD_SECTION_NAMES]
      : typeof section === 'string'
        ? new RegExp(escapeRegExp(section), 'i')
        : section;
  // Flutter 3.44 web may expose DashboardSection as group, region, or merged tabpanel.
  return page
    .getByRole('group', { name })
    .or(page.getByRole('region', { name }))
    .or(page.getByRole('tabpanel', { name }))
    .first();
}

/** Flutter FilterChip / ChoiceChip — button in older web, checkbox/tab in 3.44. */
export function filterChipByName(page: Page, pattern: string | RegExp): Locator {
  const name =
    typeof pattern === 'string' ? new RegExp(escapeRegExp(pattern), 'i') : pattern;
  return page
    .getByRole('button', { name })
    .or(page.getByRole('checkbox', { name }))
    .or(page.getByRole('tab', { name }))
    .first();
}

/**
 * Accessible name for [PetCard] on full lists (`/pc/pets`, org home): "Pet: Bella, dog".
 * Guardian Today dashboard cards use {@link guardianDashboardPetNamePattern} instead.
 */
export function petListCardNamePattern(petName: string): RegExp {
  return new RegExp(`Pet:\\s*${escapeRegExp(petName)}`, 'i');
}

/**
 * Guardian Today dashboard preview card: "Max, My Fostered Pets, All clear".
 * See `GuardianDashboardPetCard` semantics in Flutter.
 */
export function guardianDashboardPetNamePattern(petName: string): RegExp {
  return new RegExp(`^${escapeRegExp(petName)},\\s`, 'i');
}

/** Match a pet tile on either the dashboard preview or a full pet list surface. */
export function petCardNamePattern(petName: string): RegExp {
  const name = escapeRegExp(petName);
  return new RegExp(`(?:Pet:\\s*${name}|^${name},)`, 'i');
}

/** Org inventory on `/o/home` — "Pet: Max, Rescue Hearts, dog". */
export function petListCardWithOrgPattern(petName: string, orgName: string): RegExp {
  return new RegExp(
    `Pet:\\s*${escapeRegExp(petName)}.*${escapeRegExp(orgName)}`,
    'i',
  );
}

/** Org pets list index — `/o/orgs/:id/pets` only (not `/pets/:petId/...` sub-routes). */
export const ORG_PETS_LIST_ROUTE = /^\/o\/orgs\/[^/]+\/pets$/;

export function isOrgPetsListRoute(route: string): boolean {
  return ORG_PETS_LIST_ROUTE.test(route);
}

/** Locator for a visible pet card (dashboard or list semantics). */
export function petCardByName(page: Page, petName: string) {
  return semanticsByName(page, petCardNamePattern(petName));
}

/** Locator union used when asserting a pet is absent from the shell. */
export function petCardHiddenLocator(page: Page, petName: string) {
  const pattern = petCardNamePattern(petName);
  return page
    .getByRole('button', { name: pattern })
    .or(page.getByRole('group', { name: pattern }))
    .or(page.getByRole('checkbox', { name: pattern }))
    .or(page.getByRole('tab', { name: pattern }));
}

/** Care-state tail on guardian full-list cards — `{name}, {ownership}, {care}`. */
const GUARDIAN_PET_LIST_CARE_TAIL =
  '(?:All clear|Overdue|Due today|Care coming up|Passed away|Tout est en ordre|En retard|Aujourd\'hui|Soin à venir|Décédé\\(e\\))';

const GUARDIAN_ACTIVE_PET_LIST_CARE_TAIL =
  '(?:All clear|Overdue|Due today|Care coming up|Tout est en ordre|En retard|Aujourd\'hui|Soin à venir)';

/** Any pet list tile on `/pc/pets` (legacy `Pet:` prefix or guardian full-list semantics). */
export function petListCardLocator(page: Page) {
  const guardianFullList = new RegExp(
    `^[^,]+,\\s*[^,]+,\\s*${GUARDIAN_PET_LIST_CARE_TAIL}$`,
    'i',
  );
  return page
    .getByRole('button', { name: /Pet:/i })
    .or(page.getByRole('group', { name: /Pet:/i }))
    .or(page.getByRole('button', { name: guardianFullList }))
    .or(page.getByRole('group', { name: guardianFullList }));
}

/** Active (non-passed-away) tiles on guardian `/pc/pets` — excludes Passed away section cards. */
export function activePetListCardLocator(page: Page) {
  const guardianActiveList = new RegExp(
    `^(?!Passed [Aa]way|Rainbow Bridge|Décédé)[^,]+,\\s*[^,]+,\\s*${GUARDIAN_ACTIVE_PET_LIST_CARE_TAIL}$`,
    'i',
  );
  return page
    .getByRole('button', { name: /Pet:/i })
    .or(page.getByRole('group', { name: /Pet:/i }))
    .or(page.getByRole('button', { name: guardianActiveList }))
    .or(page.getByRole('group', { name: guardianActiveList }));
}

/** Home shell or a pet tile after save/create (dashboard or list). */
export function postPetMutationShellLocator(page: Page) {
  const dashboardPet = page
    .getByRole('button', {
      name: /,\s*(?:My Pets|My Fostered Pets|Shared Pets|Mes animaux|Animaux partagés)/i,
    })
    .or(
      page.getByRole('group', {
        name: /,\s*(?:My Pets|My Fostered Pets|Shared Pets|Mes animaux|Animaux partagés)/i,
      }),
    );
  return homeShellLocator(page)
    .or(petListCardLocator(page))
    .or(dashboardPet)
    .or(page.getByRole('button', { name: 'Edit Organisation' }))
    .first();
}

/** Flutter MergeSemantics nodes may surface as button, checkbox, tab, or group (3.44 web). */
export function semanticsByName(page: Page, pattern: string | RegExp) {
  const name =
    typeof pattern === 'string' ? new RegExp(escapeRegExp(pattern), 'i') : pattern;
  return page
    .getByRole('button', { name })
    .or(page.getByRole('checkbox', { name }))
    .or(page.getByRole('tab', { name }))
    .or(page.getByRole('group', { name }))
    .first();
}

/** AppLogoTitle exposes a banner like "Go to home {title}" in Flutter semantics. */
export async function expectAppBarTitle(page: Page, title: string | RegExp): Promise<void> {
  const pattern =
    typeof title === 'string'
      ? new RegExp(title.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i')
      : title;
  const { expect } = await import('@playwright/test');
  await expect(async () => {
    await refreshFlutterAccessibility(page);
    const banner = page.getByRole('banner', { name: pattern }).first();
    if (await banner.isVisible().catch(() => false)) return;
    const heading = page.getByRole('heading', { name: pattern }).first();
    if (await heading.isVisible().catch(() => false)) return;
    await expect(page.getByText(pattern).first()).toBeVisible();
  }).toPass({ timeout: 30_000 });
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

/** Fill a borderless Flutter field located by `flt-semantics-identifier` (Widget Key on web). */
export async function fillSemanticsField(
  page: Page,
  identifier: string,
  value: string,
): Promise<void> {
  const field = page.locator(`[flt-semantics-identifier="${identifier}"]`);
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

/** Toggle a canonical [CollectionFilterBar] choice (mobile sheet or desktop menu). */
export async function tapCollectionFilterChoice(
  page: Page,
  options: {
    dimensionId: string;
    choiceId: string;
    choiceLabel: string | RegExp;
    inMore?: boolean;
  },
): Promise<void> {
  const { dimensionId, choiceId, choiceLabel, inMore = false } = options;
  await refreshFlutterAccessibility(page);

  const clickChoice = async () => {
    const keyedChoice = page.locator(
      `[flt-semantics-identifier="filter_choice_${dimensionId}_${choiceId}"], [flt-semantics-identifier="filter_sheet_${dimensionId}_${choiceId}"], [flt-semantics-identifier="filter_more_${dimensionId}_${choiceId}"]`,
    );
    if (await keyedChoice.first().isVisible({ timeout: 1_000 }).catch(() => false)) {
      await keyedChoice.first().click();
      return;
    }
    await page.getByRole('checkbox', { name: choiceLabel }).click();
  };

  const mobileTrigger = page.locator(
    '[flt-semantics-identifier="collection_filter_mobile_trigger"]',
  );
  if (await mobileTrigger.isVisible({ timeout: 2_000 }).catch(() => false)) {
    await mobileTrigger.click();
    await refreshFlutterAccessibility(page);
    await clickChoice();
    const done = page.locator('[flt-semantics-identifier="collection_filter_sheet_done"]');
    if (await done.isVisible({ timeout: 1_000 }).catch(() => false)) {
      await done.click();
    }
    await refreshFlutterAccessibility(page);
    return;
  }

  if (inMore) {
    const choiceLocator = page.locator(
      `[flt-semantics-identifier="filter_more_${dimensionId}_${choiceId}"]`,
    );
    if (!(await choiceLocator.isVisible({ timeout: 500 }).catch(() => false))) {
      await page.locator('[flt-semantics-identifier="collection_filter_more_trigger"]').click();
      await refreshFlutterAccessibility(page);
    }
    await clickChoice();
  } else {
    const choiceLocator = page.locator(
      `[flt-semantics-identifier="filter_choice_${dimensionId}_${choiceId}"]`,
    );
    if (!(await choiceLocator.isVisible({ timeout: 500 }).catch(() => false))) {
      const dimensionTrigger = page.locator(
        `[flt-semantics-identifier="filter_dimension_trigger_${dimensionId}"]`,
      );
      if (await dimensionTrigger.isVisible({ timeout: 3_000 }).catch(() => false)) {
        await dimensionTrigger.click();
      } else {
        const labelPattern =
          dimensionId === 'status'
            ? /^Status( \(\d+\))?$/i
            : dimensionId === 'type'
              ? /^Type( \(\d+\))?$/i
              : new RegExp(`^${escapeRegExp(dimensionId)}( \\(\\d+\\))?$`, 'i');
        await page.getByRole('button', { name: labelPattern }).first().click();
      }
      await refreshFlutterAccessibility(page);
    }
    await clickChoice();
  }

  await refreshFlutterAccessibility(page);
  await page.waitForTimeout(300);
}
