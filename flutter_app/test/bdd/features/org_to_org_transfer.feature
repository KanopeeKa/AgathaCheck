Feature: Organisation to organisation transfer
  As an organisation admin
  I want to transfer pets to connected organisations
  So that guardianship moves only after the receiving org accepts

  Background:
    Given an organisation "Rescue Hearts" of type "Charity"
    And an organisation "Partner Shelter" of type "Charity"
    And "Alice" is a super user of "Rescue Hearts"
    And "Bob" is a super user of "Partner Shelter"

  @P1
  Scenario: Connected orgs can transfer a pet with recipient acceptance
    Given "Rescue Hearts" and "Partner Shelter" are connected organisations
    And a pet "Max" exists under "Rescue Hearts"
    When "Alice" requests an org-to-org transfer of "Max" to "Partner Shelter"
    And "Bob" accepts the custody transfer for "Max"
    Then "Partner Shelter" should be the guardian and care holder of "Max"
    And a frozen shadow of "Max" should exist for "Rescue Hearts"
    And "Max" should appear in the live inventory of "Partner Shelter"

  @P1
  Scenario: Org transfer requires an active connection
    Given a pet "Max" exists under "Rescue Hearts"
    When "Alice" requests an org-to-org transfer of "Max" to "Partner Shelter"
    Then the transfer request should be rejected because the organisations are not connected

  @P1
  Scenario: Disconnecting orgs cancels pending transfers between them
    Given "Rescue Hearts" and "Partner Shelter" are connected organisations
    And a pending org-to-org transfer exists for "Max" from "Rescue Hearts" to "Partner Shelter"
    When "Alice" disconnects from "Partner Shelter"
    Then the pending transfer for "Max" should be cancelled
