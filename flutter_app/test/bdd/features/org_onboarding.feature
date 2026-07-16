Feature: Organisation onboarding
  As a new organisation super-admin
  I want a guided setup after my first login
  So that I can create my organisation profile, add an inventory pet, and set a reminder

  @P1
  Scenario: New org super-admin sees onboarding wizard after first login
    Given a registered user with email "neworgadmin@example.com" and password "secret123"
    And the user belongs to organisation "Rescue Hearts" as super-admin
    And the user has no inventory pets
    And the user is on the login screen
    When the user enters email "neworgadmin@example.com"
    And the user enters password "secret123"
    And the user taps the "Sign In" button
    Then the user should see the organisation onboarding wizard

  @P1
  Scenario: Org super-admin completes onboarding with inventory pet and reminder
    Given a registered user with email "setuporgadmin@example.com" and password "secret123"
    And the user belongs to organisation "Rescue Hearts" as super-admin
    And the user has no inventory pets
    And the user is on the organisation onboarding wizard
    When the user completes organisation onboarding for pet "Max" with reminder "Vaccine booster"
    Then the user should be navigated to the organisation home screen
    And the pet "Max" should appear on the home screen
