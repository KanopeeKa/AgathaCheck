Feature: Fostering sessions list
  As an organisation admin
  I want to browse fostering sessions
  So that I can monitor active placements and follow up with fosters

  Background:
    Given a registered user "Alice"
    And "Alice" is a super user of organisation "Rescue Hearts"

  @P1
  Scenario: Admin can open the fostering sessions list from the profile
    Given an active fostering session for pet "Buddy" with foster "Jane Foster"
    When "Alice" opens the fostering sessions list for "Rescue Hearts"
    Then she should see "Buddy" and "Jane Foster" in the sessions list

  @P1
  Scenario: Sessions list highlights nearly finished placements
    Given an active fostering session for pet "Buddy" ending within 10 days
    When "Alice" opens the fostering sessions list for "Rescue Hearts"
    Then the session row should show a nearly finished status

  @P1
  Scenario: Admin can message a foster from the sessions list
    Given an active fostering session for pet "Buddy" with foster "Jane Foster"
    When "Alice" opens the fostering sessions list for "Rescue Hearts"
    Then she should see a mailto affordance for "Jane Foster"
