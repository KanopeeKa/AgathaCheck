Feature: Pet sharing with prospective adopters
  As an organisation super user
  I want to share organisation pets with individuals for visibility
  So that prospective adopters can collaborate without changing guardianship

  Background:
    Given an organisation "Rescue Hearts" of type "Charity"
    And "Alice" is a super user of "Rescue Hearts"

  @P1
  Scenario: Sharing an organisation pet with a prospective adopter
    Given a pet "Max" exists under "Rescue Hearts"
    And a registered user "Eve"
    When "Alice" creates a share link for "Max"
    And "Eve" accepts the share link
    Then "Eve" should see "Max" in her pet list as a shared pet
    And "Max" should still belong to "Rescue Hearts"
    And "Eve" should be able to add health entries for "Max"

  @P1
  Scenario: Viewing frozen shadow after adoption leaves the org
    Given "Eve" adopted "Max" from "Rescue Hearts"
    When "Alice" views the archived pets of "Rescue Hearts"
    Then she should see a frozen shadow snapshot of "Max"
    And the shadow should not sync with live data on "Max"
