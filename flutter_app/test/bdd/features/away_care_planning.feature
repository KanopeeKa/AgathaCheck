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
  Scenario: After-it's-done care shows an estimated date on the away plan
    Given I am signed in as a guardian with a saved planned absence
    And after-it's-done care is due before I leave with a possible next date during my trip
    When I open the away plan for that absence
    Then I should see an estimated date on the planned care row for that entry

  @P1
  Scenario: Changing a care date from the care item updates the next dates
    Given I am signed in as a guardian with a calendar-based health entry
    And the entry has an open occurrence I can reschedule
    When I change the occurrence date from the care item
    Then the care item should show updated next occurrence dates

  @P1
  Scenario: In-window care shows on the away plan during the absence
    Given I am signed in as a guardian with a saved planned absence
    And a health entry has care scheduled during the absence
    When I open the away plan for that absence
    Then I should see a planned care row for that entry

  @P1
  Scenario: Care done before the trip still appears on the away plan
    Given I am signed in as a guardian with weekly after-it's-done care due today
    And my trip starts in five days and ends in twelve days
    When I mark today's care done on time
    Then the next real occurrence should fall during the trip
    And the away plan should list that care with its occurrence id
