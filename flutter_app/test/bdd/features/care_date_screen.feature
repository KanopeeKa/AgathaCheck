Feature: Care date screen (v4)
  As a pet owner
  I want one leaf screen per care date with context, schedule, completion, and neighbours
  So that I can review and act on each date without leaving the flow

  Background:
    Given the user is logged in
    And a pet "Bella" exists

  @P1
  Scenario: CD-1 Care date shows four-block layout
    Given "Bella" has a grooming care "Spa day" due today
    When the user opens the care date for "Spa day"
    Then the care date screen should show the v4 four-block layout

  @P1
  Scenario: CD-2 Care name link opens Care details
    Given "Bella" has a grooming care "Spa day" due today
    When the user opens the care date for "Spa day"
    And the user taps the care name on the care date screen
    Then the care item view should show "Spa day"

  @P1
  Scenario: CD-3 After-it's-done overdue completes inline on the leaf without a date sheet
    Given "Bella" has after-it's-done care "Flea treat" overdue from last week
    When the user opens the care date for "Flea treat"
    And the user marks the care date as done
    Then the completion date sheet should not appear

  @P1
  Scenario: CD-4 Neighbour chevron opens the adjacent occurrence on the same route
    Given "Bella" has planned care dates "2026-06-01", "2026-06-15", and "2026-07-01" for "Course"
    When the user opens the middle care date for "Course"
    And the user opens the next neighbour on the care date screen
    Then the care date route should show the next planned date for "Course"
