Feature: Away care planning display
  As a pet parent preparing to be away
  I want honest care dates and planning help on the away plan
  So that I know what to finish before I leave and what my carer may still need to do

  @P1
  Scenario: Pre-departure overdue care links to the pet profile instead of listing on the plan
    Given I am signed in as a guardian with a saved planned absence
    And a health entry has an overdue open occurrence before the absence starts
    When I open the away plan for that absence
    Then I should see a link to review overdue care for that pet
    And I should not see a planned care row for that overdue entry

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
  Scenario: Carer task summary shows for in-window care during the absence
    Given I am signed in as a guardian with a saved planned absence
    And the away plan has in-window care tasks for my carer
    When I open the away plan for that absence
    Then I should see the carer task summary for that pet
