Feature: Guardian onboarding
  As a new pet guardian
  I want a guided setup after my first login
  So that I can add a pet and reminder quickly

  @P1
  Scenario: New guardian user sees onboarding wizard after first login
    Given a registered user with email "newguardian@example.com" and password "secret123"
    And the user has no organisation memberships
    And the user has no pets
    And the user is on the login screen
    When the user enters email "newguardian@example.com"
    And the user enters password "secret123"
    And the user taps the "Sign In" button
    Then the user should see the guardian onboarding wizard

  @P1
  Scenario: Guardian completes onboarding with pet and reminder
    Given a registered user with email "setupguardian@example.com" and password "secret123"
    And the user has no organisation memberships
    And the user has no pets
    And the user is on the guardian onboarding wizard
    When the user completes guardian onboarding for pet "Bella" with reminder "Heartworm pill"
    Then the user should be navigated to the guardian home screen
    And the pet "Bella" should appear on the home screen
