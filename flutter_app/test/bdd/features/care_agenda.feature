Feature: Care agenda
  As a pet owner
  I want actionable care rows on Today and All care
  So that I can complete or open each date quickly

  Background:
    Given the user is logged in
    And a pet "Bella" exists

  @P1
  Scenario: A care row opens Care details
    Given "Bella" has a health entry "Viewable Care" due today
    When the user navigates to the Pet Care dashboard
    And the user opens the care agenda row for "Viewable Care"
    Then the care item view should show "Viewable Care"

  @P1
  Scenario: Care that needs a weight opens Care date from Mark as done
    Given "Bella" has a weight check "Monthly weigh-in" due today
    When the user marks "Monthly weigh-in" as done from the care agenda
    Then the occurrence screen should prompt for a weight before Done is enabled

  @P1
  Scenario: Several dates to sort out open the care item
    Given "Bella" has a daily medication "Stack Meds" with two overdue dates today
    When the user taps "Mark as done" for "Stack Meds" on the care agenda
    Then the care item view should show Needs attention for "Stack Meds"

  @P1
  Scenario: Upcoming care can be marked as done early
    Given "Bella" has care "Future Groom" due in two weeks
    When the user marks "Future Groom" as done from the care agenda
    Then an early completion confirmation should appear
