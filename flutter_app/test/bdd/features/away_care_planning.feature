Feature: Away care planning display
  As a pet parent preparing to be away
  I want honest care dates and planning help on the away plan
  So that I know what to finish before I leave and what my carer may still need to do

  @P1
  Scenario: Overdue open care shows its date on the away plan
    Given I am signed in as a guardian with a saved planned absence
    And a health entry has an overdue open occurrence before the absence starts
    When I open the away plan for that absence
    Then I should see the overdue date on the planned care row for that entry

  @P1
  Scenario: Completion-based care shows an estimated date on the away plan
    Given I am signed in as a guardian with a saved planned absence
    And a completion-based health entry has care scheduled during the absence
    When I open the away plan for that absence
    Then I should see an estimated date on the planned care row for that entry

  @P1
  Scenario: Changing a care date from the care item updates the next dates
    Given I am signed in as a guardian with a calendar-based health entry
    And the entry has an open occurrence I can reschedule
    When I change the occurrence date from the care item
    Then the care item should show updated next occurrence dates

  @P1
  Scenario: Accepting a planner suggestion reduces carer tasks during the absence
    Given I am signed in as a guardian with a saved planned absence
    And the away plan shows a planner suggestion to move care before the absence
    When I accept the planner suggestion
    Then the carer task count for the absence should drop
