/**
 * @bdd help_faq.feature
 * Scenario: Opening the Help page from the user menu
 * Scenario: Help page displays the title
 * Scenario: Help page shows all feature sections
 * Scenario: Expanding a FAQ section
 * Scenario: Collapsing a FAQ section
 * Scenario: Multiple sections can be expanded
 * Scenario: Help page is scrollable
 * Scenario: Help page content in English
 * Scenario: Help page content in French
 * Scenario: Navigating back from the Help page
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import { PetListPage } from '../pages/pet-list.page';
import { MyDetailsPage } from '../pages/my-details.page';
import {
  FAQ_SECTIONS_EN,
  FAQ_SECTIONS_FR,
  HelpPage,
} from '../pages/help.page';

const EN_SUBTITLE =
  'Find answers to common questions about every feature in Agatha Track.';
const FR_SUBTITLE =
  'Trouvez les réponses à vos questions sur toutes les fonctionnalités d\'Agatha Track.';

const PET_PROFILES_Q1 = 'How do I add a new pet?';
const PET_PROFILES_A1_SNIPPET = 'Tap the "+" button on the main pet list screen';
const ACCOUNT_Q1 = 'How do I create an account?';
const HEALTH_Q1 = 'What types of health entries can I track?';

test.describe('Help / FAQ', () => {
  test('user can open Help from the user menu', async ({ page, testUser }) => {
    await loginAs(page, testUser);

    const help = new HelpPage(page);
    await help.openFromUserMenu();
    await help.expectLoaded();
  });

  test('Help page displays the title', async ({ page, testUser }) => {
    await loginAs(page, testUser);

    const help = new HelpPage(page);
    await help.openFromUserMenu();
    await help.expectTitle('Help & FAQ');
  });

  test('Help page shows all feature sections', async ({ page, testUser }) => {
    await loginAs(page, testUser);

    const help = new HelpPage(page);
    await help.openFromUserMenu();
    await help.expectAllSections(FAQ_SECTIONS_EN);
  });

  test('user can expand a FAQ section to reveal Q&A pairs', async ({ page, testUser }) => {
    await loginAs(page, testUser);

    const help = new HelpPage(page);
    await help.openFromUserMenu();
    await help.expandSection('Pet Profiles');
    await help.expectSectionQuestionsVisible('Pet Profiles', PET_PROFILES_Q1);
    await help.expectQuestionAndAnswer(
      PET_PROFILES_Q1,
      PET_PROFILES_A1_SNIPPET,
    );
  });

  test('user can collapse an expanded FAQ section', async ({ page, testUser }) => {
    await loginAs(page, testUser);

    const help = new HelpPage(page);
    await help.openFromUserMenu();
    await help.expandSection('Pet Profiles');
    await help.expectSectionQuestionsVisible('Pet Profiles', PET_PROFILES_Q1);
    await help.collapseSection('Pet Profiles');
    await help.expectSectionQuestionsHidden(PET_PROFILES_Q1);
  });

  test('multiple FAQ sections can stay expanded at once', async ({ page, testUser }) => {
    await loginAs(page, testUser);

    const help = new HelpPage(page);
    await help.openFromUserMenu();
    await help.expandSection('Account & Authentication');
    await help.expandSection('Health Tracking');
    await help.expectSectionQuestionsVisible('Account & Authentication', ACCOUNT_Q1);
    await help.expectSectionQuestionsVisible('Health Tracking', HEALTH_Q1);
  });

  test('Help page is scrollable through all FAQ sections', async ({ page, testUser }) => {
    await loginAs(page, testUser);

    const help = new HelpPage(page);
    await help.openFromUserMenu();
    await help.scrollToSection('Subscription');
    await expect(page.getByText('Subscription', { exact: true }).first()).toBeVisible();
    await help.scrollToSection('Language & Accessibility');
    await expect(
      page.getByText('Language & Accessibility', { exact: true }).first(),
    ).toBeVisible();
  });

  test('Help page content is displayed in English by default', async ({ page, testUser }) => {
    await loginAs(page, testUser);

    const help = new HelpPage(page);
    await help.openFromUserMenu();
    await help.expectTitle('Help & FAQ');
    await help.expectSubtitle(EN_SUBTITLE);
    await help.expectAllSections(FAQ_SECTIONS_EN);
  });

  test('Help page content is displayed in French when locale is French', async ({
    page,
    testUser,
  }) => {
    await loginAs(page, testUser);

    const myDetails = new MyDetailsPage(page);
    await myDetails.openFromUserMenu();
    await myDetails.setLanguage('fr');

    const help = new HelpPage(page);
    await help.openFromUserMenu();
    await help.expectTitle('Aide & FAQ');
    await help.expectSubtitle(FR_SUBTITLE);
    await help.expectAllSections(FAQ_SECTIONS_FR);
  });

  test('user can navigate back from Help to the pet list', async ({ page, testUser }) => {
    const petList = await loginAs(page, testUser);

    const help = new HelpPage(page);
    await help.openFromUserMenu();
    await help.goBack();

    await petList.expectLoaded();
    await expect(page.getByRole('button', { name: 'Add Pet' })).toBeVisible();
  });
});
