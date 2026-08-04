Feature: Account area
  As a signed-in user
  I want account preferences for organisation visibility
  So that I control when the Organisation section appears

  @P1
  Scenario: Guardian-only user can enable show organisation section
    Given a registered user with email "guardian@example.com" and password "secret123"
    And the user has no organisation memberships
    And the user is on the account screen
    When the user enables "Show organisation section"
    Then the drawer should contain "Organisation" as a section item

  @P1
  Scenario: Org member cannot disable show organisation section
    Given a registered user with email "dual@example.com" and password "secret123"
    And the user belongs to an organisation
    And the user is on the account screen
    Then the "Show organisation section" toggle should be on and disabled
    And the user should see organisation visibility locked explanation text

  @P1
  Scenario: Login restores last active organisation section
    Given a registered user with email "dual@example.com" and password "secret123"
    And the user belongs to an organisation
    And the user has personal guardian pets
    And the user has last app section "organization"
    And the user is on the login screen
    When the user enters email "dual@example.com"
    And the user enters password "secret123"
    And the user taps the "Sign In" button
    Then the user should be navigated to the organisation home screen

  @P1
  Scenario: Login restores last active guardian section
    Given a registered user with email "dual@example.com" and password "secret123"
    And the user belongs to an organisation
    And the user has personal guardian pets
    And the user has last app section "guardian"
    And the user is on the login screen
    When the user enters email "dual@example.com"
    And the user enters password "secret123"
    And the user taps the "Sign In" button
    Then the user should be navigated to the guardian home screen
