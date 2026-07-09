Feature: GDPR data rights
  As a registered user
  I want to export my data and delete my account
  So that I can exercise my data-subject rights under GDPR

  Background:
    Given the user is logged in

  @P2
  Scenario: Exporting my personal data as JSON
    Given the user has a pet "Bella" in their account
    When the user exports their data from My Details
    Then the export should include the user profile
    And the export should include pet "Bella"

  @P2
  Scenario: Deleting my account with password confirmation
    Given the user is on the My Details screen
    When the user deletes their account with their password
    Then the user should be logged out
    And the user should not be able to log in again
