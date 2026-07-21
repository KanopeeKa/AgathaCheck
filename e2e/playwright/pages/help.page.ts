import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  expectAppBarTitle,
  flutterGotoUrl,
  isExperienceShellVisible,
  navigateWithShellFallback,
  refreshFlutterAccessibility,
  waitForFlutterRoutePattern,
} from '../support/flutter';

/** English FAQ section titles from app_en.arb. */
export const FAQ_SECTIONS_EN = [
  'Account & Authentication',
  'Pet Profiles',
  'Health Tracking',
  'Weight Tracking',
  'Veterinarian Management',
  'Pet Sharing',
  'Organisations',
  'Family Events',
  'Notifications',
  'Reports',
  'Subscription',
  'Language & Accessibility',
] as const;

/** French FAQ section titles from app_fr.arb. */
export const FAQ_SECTIONS_FR = [
  'Compte & Authentification',
  'Profils des animaux',
  'Suivi de santé',
  'Suivi du poids',
  'Gestion des vétérinaires',
  'Partage d\'animaux',
  'Organisations',
  'Événements familiaux',
  'Notifications',
  'Rapports',
  'Abonnement',
  'Langue & Accessibilité',
] as const;

/**
 * Help & FAQ screen (`/help`).
 * Maps to: flutter_app/test/bdd/features/help_faq.feature
 */
export class HelpPage {
  constructor(private readonly page: Page) {}

  async openFromUserMenu(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    const legacyMenu = this.page.getByRole('button', { name: /user menu|menu utilisateur/i });
    if (await legacyMenu.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await legacyMenu.click();
      await this.page.waitForTimeout(500);
      await this.page
        .getByRole('menuitem', { name: /help|aide/i })
        .or(this.page.getByText('Help', { exact: true }))
        .or(this.page.getByText('Aide', { exact: true }))
        .first()
        .click();
      await this.expectLoaded();
      return;
    }

    if (await isExperienceShellVisible(this.page)) {
      await this.page.goto(flutterGotoUrl('/help'));
      await refreshFlutterAccessibility(this.page);
      await waitForFlutterRoutePattern(this.page, /\/help$/, 30_000);
      await this.expectLoaded();
      return;
    }

    await navigateWithShellFallback(
      this.page,
      /\/help(?:\?|$)/,
      '/help',
      () => this.expectLoaded(),
      { helper: 'help.openFromUserMenu', testTitle: null },
    );
  }

  async expectLoaded(title: string | RegExp = /Help & FAQ|Aide & FAQ/i): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await refreshFlutterAccessibility(this.page);
    await expectAppBarTitle(this.page, title);
  }

  async expectTitle(title: string): Promise<void> {
    await this.expectLoaded(title);
  }

  async expectAllSections(sections: readonly string[]): Promise<void> {
    for (const section of sections) {
      await this.scrollToSection(section);
      await expect(this.page.getByText(section, { exact: true }).first()).toBeVisible({
        timeout: 15_000,
      });
    }
  }

  async scrollToSection(sectionTitle: string): Promise<void> {
    const heading = this.page.getByText(sectionTitle, { exact: true }).first();
    await heading.scrollIntoViewIfNeeded();
    await this.page.waitForTimeout(300);
  }

  async expandSection(sectionTitle: string): Promise<void> {
    await this.scrollToSection(sectionTitle);
    await this.page.getByText(sectionTitle, { exact: true }).first().click();
    await this.page.waitForTimeout(400);
    await refreshFlutterAccessibility(this.page);
  }

  async collapseSection(sectionTitle: string): Promise<void> {
    await this.expandSection(sectionTitle);
  }

  async expectSectionQuestionsVisible(sectionTitle: string, sampleQuestion: string): Promise<void> {
    const questionPattern = new RegExp(
      sampleQuestion.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'),
      'i',
    );
    await expect(
      this.page
        .getByRole('button', { name: questionPattern })
        .or(this.page.getByRole('group', { name: questionPattern }))
        .first(),
    ).toBeVisible({
      timeout: 15_000,
    });
  }

  async expectSectionQuestionsHidden(sampleQuestion: string): Promise<void> {
    await expect(this.page.getByText(sampleQuestion, { exact: true })).toHaveCount(0);
  }

  async expandQuestion(question: string): Promise<void> {
    await this.page.getByText(question, { exact: true }).first().click();
    await this.page.waitForTimeout(400);
    await refreshFlutterAccessibility(this.page);
  }

  async expectQuestionAndAnswer(question: string, answerSnippet: string): Promise<void> {
    const answerPattern = new RegExp(
      answerSnippet.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'),
      'i',
    );
    await expect(this.page.getByRole('button', { name: question, exact: true }).first()).toBeVisible({
      timeout: 15_000,
    });
    await this.expandQuestion(question);
    await expect(
      this.page
        .getByRole('group', { name: answerPattern })
        .or(this.page.getByText(answerSnippet, { exact: false }))
        .first(),
    ).toBeVisible({
      timeout: 15_000,
    });
  }

  async expectSubtitle(subtitle: string): Promise<void> {
    await expect(this.page.getByText(subtitle, { exact: true }).first()).toBeVisible({
      timeout: 15_000,
    });
  }

  async goBack(): Promise<void> {
    const backButton = this.page.getByRole('button', { name: /^(Back|Retour)$/i });
    if (await backButton.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await backButton.click();
    } else if (await isExperienceShellVisible(this.page)) {
      const homeNav = this.page.getByRole('button', { name: /^(Home|Accueil)$/i });
      if (await homeNav.isVisible({ timeout: 2_000 }).catch(() => false)) {
        await homeNav.click({ force: true });
        await waitForFlutterRoutePattern(this.page, /\/(g|o)\/home/, 30_000);
      } else {
        await this.page.goto(flutterGotoUrl('/g/home'));
        await refreshFlutterAccessibility(this.page);
        await waitForFlutterRoutePattern(this.page, /^\/g\/home$/, 30_000);
      }
    } else {
      await this.page.goBack();
    }
    await this.page.waitForTimeout(500);
    await refreshFlutterAccessibility(this.page);
  }
}
