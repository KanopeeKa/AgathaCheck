Feature: Fostering platform journeys
  As an organisation admin
  I want capacity-aware foster matching, session activity tabs, visits, and adoption journeys
  So that the full fostering platform roadmap is operable end-to-end

  Background:
    Given an organisation "Rescue Hearts" of type "Charity"
    And "Alice" is a super user of "Rescue Hearts"
    And a registered user "Eve" is a foster parent of "Rescue Hearts"

  @P2
  Scenario: Foster request targets respect approved capacity filters
    Given a pet "Max" exists under "Rescue Hearts"
    When "Alice" views eligible foster targets for "Max"
    Then only approved fosters with available capacity should be listed

  @P2
  Scenario: Manage Fosters tabs use fostering activity summary
    Given "Eve" is approved as a foster parent of "Rescue Hearts"
    When "Alice" opens Manage Fosters for "Rescue Hearts"
    Then foster parents should be grouped by fostering activity summary

  @P2
  Scenario: Positive adoption visit outcome gates journey start on visit path
    Given "Max" is in a foster-in-view-to-adopt session with "Eve"
    And an adoption visit for "Max" is completed with a positive outcome
    When "Alice" starts the adoption journey for "Max"
    Then the adoption journey should be awaiting foster confirmation
