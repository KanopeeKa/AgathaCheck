Feature: Account area
  As a signed-in user
  I want account preferences for organisation visibility
  So that I control when the Organisation section appears

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
