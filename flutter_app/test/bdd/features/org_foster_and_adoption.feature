Feature: Organisation foster and adoption
  As an organisation admin
  I want to foster pets to individuals and complete adoptions
  So that guardianship transfers only when care and guardianship leave the org

  Background:
    Given an organisation "Rescue Hearts" of type "Charity"
    And "Alice" is a super user of "Rescue Hearts"
    And a registered user "Eve" is a foster parent of "Rescue Hearts"

  @P1
  Scenario: Foster placement gives Eve care while Rescue Hearts keeps guardianship
    Given a pet "Max" exists under "Rescue Hearts"
    When "Alice" starts a foster placement for "Max" with "Eve"
    And "Eve" accepts the foster placement
    Then "Rescue Hearts" should still be the guardian of "Max"
    And "Eve" should provide day-to-day care for "Max"
    And "Max" should appear in the live inventory of "Rescue Hearts"

  @P1
  Scenario: Direct adoption requires foster confirmation
    Given a pet "Max" exists under "Rescue Hearts"
    When "Alice" initiates direct adoption of "Max" to "Eve"
    And "Eve" confirms adoption of "Max"
    Then "Eve" should be the guardian and care holder of "Max"
    And "Max" should no longer appear in the live inventory of "Rescue Hearts"
    And a frozen shadow of "Max" should exist for "Rescue Hearts"

  @P1
  Scenario: Org admin hides a fostered pet from their home list only
    Given "Max" is fostered from "Rescue Hearts" to "Eve"
    When "Alice" hides "Max" from her home pet list
    Then "Max" should not appear on "Alice"'s home pet list
    And "Max" should still appear in the organisation section for "Rescue Hearts"

  @P1
  Scenario: Fosterer hides a fostered pet from notifications and health dashboard
    Given "Max" is fostered from "Rescue Hearts" to "Eve"
    When "Eve" hides "Max"
    Then "Max" should not appear in "Eve"'s pet list
    And "Max" should not generate notifications for "Eve"
    And "Max" should not appear in "Eve"'s health dashboard

  @P1
  Scenario: Hide is cleared when foster ends
    Given "Max" is fostered from "Rescue Hearts" to "Eve"
    And "Alice" has hidden "Max" from her home pet list
    When "Alice" ends the foster placement for "Max"
    Then "Max" should appear on "Alice"'s home pet list again
