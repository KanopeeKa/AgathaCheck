Feature: Fostering session detail view
  As a foster carer
  I want to open my fostering session from the pet profile
  So that I can review status and take participant actions

  Background:
    Given a registered user "Jane Foster"
    And "Jane Foster" has a pending foster placement invite for pet "Buddy" from organisation "Rescue Hearts"

  @P1
  Scenario: Foster carer opens session detail from pending invite
    When "Jane Foster" opens the fostering session for pet "Buddy"
    Then she should see the fostering session detail screen
    And she should see accept and decline invite actions
