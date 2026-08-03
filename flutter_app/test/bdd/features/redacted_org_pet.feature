Feature: Redacted organisation pet profile
  As an associate member with view_org_pets
  I want to open a summary-only pet profile from the organisation hub
  So that I can learn about pets without operational access

  Background:
    Given a registered user "Alice"
    And "Alice" is a super user of organisation "Rescue Hearts"
    And a registered user "Bob"
    And "Bob" is a member of "Rescue Hearts" with role "associate"

  @P1
  Scenario: Associate sees pet preview on organisation profile
    Given an organisation pet "Buddy" exists in "Rescue Hearts"
    When "Bob" opens the organisation profile for "Rescue Hearts"
    Then he should see "Buddy" in the pets preview section

  @P1
  Scenario: Associate tap opens redacted pet profile with summary fields only
    Given an organisation pet "Buddy" exists in "Rescue Hearts"
    When "Bob" opens the redacted pet profile for "Buddy" in "Rescue Hearts"
    Then he should see summary fields for "Buddy"
    And operational pet sections should not be available

  @P1
  Scenario: Redacted pet API exposes allowlisted fields only
    Given an organisation pet "Buddy" exists in "Rescue Hearts"
    When "Bob" requests the redacted pet API for "Buddy" in "Rescue Hearts"
    Then the response should include only associate-safe pet fields
