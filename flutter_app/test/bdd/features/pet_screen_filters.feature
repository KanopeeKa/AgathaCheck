Feature: Pet screen filters
  As an organisation member with pet visibility
  I want to filter pets by their care status
  So that I can quickly find pets that need attention

  @P1
  Scenario: A pet with no foster placement needs attention
    Given "Max" has never been placed in foster care
    When I view the organisation Pets screen "Need attention" tab
    Then I should see "Max" with the explanation "Not in foster"

  @P1
  Scenario: A pet with a foster placement ending soon needs attention
    Given "Bella" is in foster care ending in 5 days with no next session planned
    When I view the organisation Pets screen "Need attention" tab
    Then I should see "Bella" with the explanation "Foster finishing soon"

  @P1
  Scenario: In foster tab shows pets currently in foster care
    Given "Bella" is in foster care ending in 30 days with no next session planned
    When I view the organisation Pets screen "In foster" tab
    Then I should see "Bella" in the pet list

  @P1
  Scenario: Name filter narrows pets on the All tab
    Given the organisation has pets "Max" and "Bella"
    When I view the organisation Pets screen "All" tab with name filter "Max"
    Then I should see "Max" in the pet list
    And I should not see "Bella" in the pet list

  @P2
  Scenario: Shadow filter shows adopted shadow pets on the All tab
    Given "Shadow" is an adopted shadow pet in the organisation
    When I view the organisation Pets screen "All" tab with shadow filter enabled
    Then I should see "Shadow" in the pet list

  @P2
  Scenario: Need attention info icon explains care criteria
    When I view the organisation Pets screen "Need attention" tab
    Then I should see the need attention info icon with guidance text
