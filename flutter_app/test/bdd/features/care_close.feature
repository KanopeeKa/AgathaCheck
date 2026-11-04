@pet_care @care_status
Feature: Close and closed care list

  @frozen
  Scenario: All care shows Closed care link when pet has closed items
    Given a pet with a closed care item
    When the pet parent opens All care
    Then they see a Closed care link with the item count

  @frozen
  Scenario: Closed care list rows show status without dates
    Given a pet with closed care items
    When the pet parent opens Closed care from All care
    Then each row shows Closed status without a due date
    And tapping a row opens read-only Care details
