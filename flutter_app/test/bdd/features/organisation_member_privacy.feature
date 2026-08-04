Feature: Organisation member privacy
  As an organisation member
  I want per-organisation privacy settings under Account
  So that I control who sees my contact details and can leave an organisation

  @P1
  Scenario: Member updates privacy settings from Account
    Given a registered user with email "dual@example.com" and password "secret123"
    And the user belongs to an organisation
    And the user is on the account screen
    When the user opens organisation privacy settings for their organisation
    And the user sets card visibility to "Admins only"
    And the user saves organisation privacy settings
    Then the user should see privacy settings saved confirmation

  @P1
  Scenario: Profile Leave navigates to Account org settings
    Given a registered user with email "dual@example.com" and password "secret123"
    And the user belongs to an organisation
    And the user is on the organisation profile screen
    When the user chooses Leave organisation from the profile menu
    Then the user should be on the account organisation privacy settings screen
    And the leave organisation section should be visible
