Feature: Away care planning display
  As a pet parent preparing to be away
  I want overdue care to show real dates on the away plan
  So that I know what to finish before I leave

  @P1
  Scenario: Overdue open care shows its date on the away plan
    Given I am signed in as a guardian with a saved planned absence
    And a health entry has an overdue open occurrence before the absence starts
    When I open the away plan for that absence
    Then I should see the overdue date on the planned care row for that entry
