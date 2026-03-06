Feature: Help / FAQ
  As a user
  I want to access a Help page with frequently asked questions
  So that I can learn how to use all the app features

  Background:
    Given the user is logged in

  # ── Accessing Help ───────────────────────────────────────────

  Scenario: Opening the Help page from the user menu
    When the user opens the user menu
    And the user taps "Help"
    Then the user should be navigated to the Help screen

  Scenario: Help page displays the title
    When the user navigates to the Help screen
    Then the page title should be "Help & FAQ"

  # ── FAQ Sections ─────────────────────────────────────────────

  Scenario: Help page shows all feature sections
    When the user views the Help screen
    Then the user should see FAQ sections for:
      | section                |
      | Account & Login        |
      | Pet Profiles           |
      | Health Tracking        |
      | Weight Tracking        |
      | Veterinarian Management|
      | Sharing                |
      | Organizations          |
      | Family Events          |
      | Notifications          |
      | Subscriptions          |
      | PDF Reports            |
      | Language / Localization |

  Scenario: Expanding a FAQ section
    When the user taps on the "Pet Profiles" section
    Then the section should expand to show Q&A pairs
    And each Q&A pair should have a question and answer

  Scenario: Collapsing a FAQ section
    Given the "Pet Profiles" section is expanded
    When the user taps on the "Pet Profiles" section header again
    Then the section should collapse

  Scenario: Multiple sections can be expanded
    When the user expands "Account & Login" and "Health Tracking"
    Then both sections should be visible with their Q&A content

  # ── Scrolling ────────────────────────────────────────────────

  Scenario: Help page is scrollable
    When the user views the Help screen
    Then the user should be able to scroll through all FAQ sections

  # ── Localization ─────────────────────────────────────────────

  Scenario: Help page content in English
    Given the app language is set to English
    When the user views the Help screen
    Then all FAQ content should be displayed in English

  Scenario: Help page content in French
    Given the app language is set to French
    When the user views the Help screen
    Then all FAQ content should be displayed in French

  # ── Navigation ───────────────────────────────────────────────

  Scenario: Navigating back from the Help page
    Given the user is on the Help screen
    When the user taps the back button
    Then the user should be navigated to the pet list screen
