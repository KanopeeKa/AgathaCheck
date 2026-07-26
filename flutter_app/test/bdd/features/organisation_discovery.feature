Feature: Organisation discovery
  As any visitor, signed in or not
  I want to browse organisations that haven't opted out of discovery
  So that I can find a shelter to support or foster for

  @P1
  Scenario: Discover Organisations is visible without signing in
    Given "Rescue Hearts" is discoverable
    When an anonymous visitor requests the organisations discovery list
    Then "Rescue Hearts" should appear with its name, logo, town, and description
    And no contact or legal details should be included

  @P1
  Scenario: An organisation can opt out of discovery
    Given "Quiet Shelter" has opted out of discovery
    When an anonymous visitor requests the organisations discovery list
    Then "Quiet Shelter" should not appear
