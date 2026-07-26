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
