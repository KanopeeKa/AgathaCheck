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
  Scenario: User switches to organisation view from guardian drawer
    Given a registered user with email "dual@example.com" and password "secret123"
    And the user belongs to an organisation
    And the user is on the guardian home screen
    When the user opens the settings menu
    And the user taps "Organisation view"
    Then the user should be navigated to the organisation home screen

  @P2
  Scenario: Guardian chooser hides organisation option for guardian-only users
    Given a registered user with email "guardian@example.com" and password "secret123"
    And the user has no organisation memberships
    And the user is on the experience chooser screen
    Then the "Shelter / Organisation" option should not be visible
