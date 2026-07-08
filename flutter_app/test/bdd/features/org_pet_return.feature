Feature: Organisation pet return
  As a current guardian
  I want to return a pet to the original rescue organisation
  So that the live pet is restored and the shadow is removed

  Background:
    Given an organisation "Rescue Hearts" of type "Charity"
    And "Alice" is a super user of "Rescue Hearts"
    And a registered user "Eve"

  @P1
  Scenario: Individual guardian returns an adopted pet to Rescue Hearts
    Given "Eve" adopted "Max" from "Rescue Hearts"
    And a frozen shadow of "Max" exists for "Rescue Hearts"
    When "Eve" requests return of "Max" to "Rescue Hearts"
    And "Alice" accepts the return of "Max"
    Then "Rescue Hearts" should be the guardian and care holder of "Max"
    And the shadow of "Max" for "Rescue Hearts" should be deleted
    And health history recorded while "Max" was away should remain on the live pet

  @P1
  Scenario: Receiving org returns a transferred pet to the sending org
    Given an organisation "Partner Shelter" of type "Charity"
    And "Bob" is a super user of "Partner Shelter"
    And "Max" was transferred from "Rescue Hearts" to "Partner Shelter"
    When "Bob" requests return of "Max" to "Rescue Hearts"
    And "Alice" accepts the return of "Max"
    Then "Rescue Hearts" should be the guardian and care holder of "Max"
    And the shadow of "Max" for "Rescue Hearts" should be deleted
