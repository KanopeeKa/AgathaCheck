Feature: Pet timeline
  As a pet's guardian or an organisation admin
  I want to see a chronological timeline of the pet's custody and fostering history
  So that I understand its full journey without a separate family-events screen

  @P1
  Scenario: Timeline shows a fostering session card
    Given "Max" had a fostering session with "Frank" from "2025-06-01" to "2025-08-31"
    When I view "Max"'s timeline
    Then I should see a fostering session card for "Frank" with those dates

  @P1
  Scenario: Timeline shows a placeholder when no data exists for a period
    Given "Max" has no recorded custody, session, or manual entry for a period
    When I view "Max"'s timeline
    Then I should see a "No data" placeholder for that period
    And I should be able to fill it with a title, description, start date, and end date
