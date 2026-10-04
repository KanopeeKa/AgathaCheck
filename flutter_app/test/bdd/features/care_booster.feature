Feature: Vaccination booster course
  As a pet owner
  I want to plan a booster when I add a vaccine
  So that the next dose follows the course before yearly recurrence

  Background:
    Given the user is logged in
    And a pet "Rex" exists

  @P1
  Scenario: PL-1 first dose then booster then yearly recurrence
    Given "Rex" has yearly vaccination "DHPP" due on "2026-06-01" with booster "2026-07-01"
    When the user completes each open date for "DHPP" on the care item
    Then the next open date for "DHPP" should be "2027-07-01"
