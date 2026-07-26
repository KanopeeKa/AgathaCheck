Feature: Experience navigation
  As a user of Agatha Track
  I want to enter the right experience after login
  So that guardian and organisation journeys stay separate

  # ── Experience chooser ───────────────────────────────────────

  @P0
  Scenario: Guardian-only user lands on guardian home after login
    Given a registered user with email "guardian@example.com" and password "secret123"
    And the user has no organisation memberships
    And the user is on the login screen
    When the user enters email "guardian@example.com"
    And the user enters password "secret123"
    And the user taps the "Sign In" button
    Then the user should be navigated to the guardian home screen

  @P1
  Scenario: Organisation-only user lands on organisation home after login
    Given a registered user with email "orgadmin@example.com" and password "secret123"
    And the user belongs to an organisation
    And the user has no personal guardian pets
    And the user is on the login screen
    When the user enters email "orgadmin@example.com"
    And the user enters password "secret123"
    And the user taps the "Sign In" button
    Then the user should be navigated to the organisation home screen

  @P1
  Scenario: Dual-role user sees experience chooser after login
    Given a registered user with email "dual@example.com" and password "secret123"
    And the user belongs to an organisation
    And the user has personal guardian pets
    And the user is on the login screen
    When the user enters email "dual@example.com"
    And the user enters password "secret123"
    And the user taps the "Sign In" button
    Then the user should see the experience chooser screen

  @P1
  Scenario: Dual-role chooser pre-selects guardian
    Given a registered user with email "dual@example.com" and password "secret123"
    And the user belongs to an organisation
    And the user has personal guardian pets
    And the user is on the experience chooser screen
    Then the "Individual Pet Guardian" option should be selected
    When the user taps continue
    Then the user should be navigated to the guardian home screen

  @P1
  Scenario: Dual-role user remembers guardian choice
    Given a registered user with email "dual@example.com" and password "secret123"
    And the user belongs to an organisation
    And the user has personal guardian pets
    And the user is on the experience chooser screen
    When the user selects "Individual Pet Guardian"
    And the user ticks "Remember my choice for next time"
    And the user taps continue
    Then the user should be navigated to the guardian home screen

  @P1
  Scenario: Remembered guardian choice skips chooser on next login
    Given a registered user with email "dual@example.com" and password "secret123"
    And the user belongs to an organisation
    And the user has personal guardian pets
    And the user has saved default experience "guardian"
    And the user is on the login screen
    When the user enters email "dual@example.com"
    And the user enters password "secret123"
    And the user taps the "Sign In" button
    Then the user should be navigated to the guardian home screen

  @P1
  Scenario: Dual-role user sets default experience to organisation in settings
    Given a registered user with email "dual@example.com" and password "secret123"
    And the user belongs to an organisation
    And the user has personal guardian pets
    And the user is on the guardian settings screen
    When the user selects "Shelter / Organisation" as the default experience
    And the user logs out of the app
    And the user logs in with email "dual@example.com" and password "secret123"
    Then the user should be navigated to the organisation home screen

  # Superseded by the navigation reversal (docs/experience-program/decisions-log.md D1, D5) —
  # the drawer no longer has a "settings menu" switch; replaced by the section-switcher scenario
  # below that asserts the unified drawer directly (see phase-1-navigation.md).
  @legacy
  @P1
  Scenario: User switches to organisation view from guardian drawer
    Given a registered user with email "dual@example.com" and password "secret123"
    And the user belongs to an organisation
    And the user is on the guardian home screen
    When the user opens the settings menu
    And the user taps "Organisation view"
    Then the user should be navigated to the organisation home screen

  # ── Section-switcher drawer (navigation reversal, phase-1-navigation.md) ──

  @P1
  Scenario: Drawer shows exactly three destinations regardless of current mode
    Given a registered user with email "dual@example.com" and password "secret123"
    And the user belongs to an organisation
    And the user has personal guardian pets
    And the user is on the guardian home screen
    When the user opens the hamburger drawer
    Then the drawer should contain "Guardian" as a section item
    And the drawer should contain "Organisation" as a section item
    And the drawer should contain "Account" as the bottom-pinned item
    And the drawer should not contain "Events" as a drawer item
    And the drawer should not contain "My vets" as a drawer item
    And the drawer should not contain "Notifications" as a drawer item
    And the drawer should not contain "Settings" as a drawer item

  @P1
  Scenario: Bell shows a single combined unread badge across both notification kinds
    Given a registered user with email "guardian@example.com" and password "secret123"
    And the user has no organisation memberships
    And the user is on the guardian home screen
    And the user has 2 unread care notifications and 1 unread administrative notification
    Then the bell badge should show "3"

  @P1
  Scenario: Hamburger is shown only on section root screens
    Given a registered user with email "guardian@example.com" and password "secret123"
    And the user has no organisation memberships
    And the user is on the guardian home screen
    Then the hamburger menu button should be visible
    When the user navigates to a sub-screen
    Then the back arrow should be visible instead of the hamburger

  @P2
  Scenario: Guardian chooser hides organisation option for guardian-only users
    Given a registered user with email "guardian@example.com" and password "secret123"
    And the user has no organisation memberships
    And the user is on the experience chooser screen
    Then the "Shelter / Organisation" option should not be visible
