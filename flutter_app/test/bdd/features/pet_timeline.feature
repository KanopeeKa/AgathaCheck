Feature: Pet timeline
  As a pet's guardian or an organisation admin
  I want to see a chronological timeline of the pet's custody and fostering history
  So that I understand its full journey without a separate family-events screen

  @P1
  Scenario: Timeline screen shows a fostering session card
    Given "Max" had a fostering session with "Frank" from "2025-06-01" to "2025-08-31"
    When I view "Max"'s timeline screen
    Then I should see a fostering session card for "Frank" with those dates

  @P1
  Scenario: Timeline screen shows date of birth and joined markers
    Given "Max" has a date of birth and joined Agatha Track
    When I view "Max"'s timeline screen
    Then I should see a date of birth entry
    And I should see a joined Agatha Track entry

  @P1
  Scenario: Guardian navigates to timeline from pet profile
    Given I am viewing "Max"'s pet profile
    When I tap the timeline navigation row
    Then I should see the timeline list screen for "Max"
