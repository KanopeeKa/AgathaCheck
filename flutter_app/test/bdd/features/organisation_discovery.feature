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

  @P1
  Scenario: Discover API returns display_locality from postcode when set
    Given "Rescue Hearts" has postcode "62701" in public profile metadata
    And "Rescue Hearts" has town "Springfield" and administrative area "IL"
    When an anonymous visitor requests the organisations discovery list
    Then "Rescue Hearts" should appear with display_locality "62701"

  @P1
  Scenario: Discover API includes photo_url for hero imagery
    Given "Rescue Hearts" is discoverable with a cover photo
    When an anonymous visitor requests the organisations discovery list
    Then "Rescue Hearts" should include photo_url in the discovery response

  @P1
  Scenario: Discover API falls back display_locality to town then administrative area
    Given "Rescue Hearts" has no postcode in public profile metadata
    And "Rescue Hearts" has town "Springfield" and administrative area "IL"
    When an anonymous visitor requests the organisations discovery list
    Then "Rescue Hearts" should appear with display_locality "Springfield"

  @P1
  Scenario: Discover API filters organisations by name when q is provided
    Given "Rescue Hearts" is discoverable
    And "Happy Tails Rescue" is discoverable
    When an anonymous visitor searches discoverable organisations for "Hearts"
    Then "Rescue Hearts" should appear in the discovery response
    And "Happy Tails Rescue" should not appear in the discovery response

  @P1
  Scenario: Discover API search preserves pagination metadata
    Given "Rescue Hearts" is discoverable
    When an anonymous visitor searches discoverable organisations for "Hearts" with page 2 and page_size 5
    Then the discovery response page should be 2
    And the discovery response page_size should be 5

  @P1
  Scenario: Connections screen Discover CTA opens discover with org browse-as context
    Given "Rescue Hearts" is discoverable
    And a registered user "Alice"
    And "Alice" is a super user of organisation "Happy Paws Clinic"
    When "Alice" opens the connected organisations screen for "Happy Paws Clinic"
    And she taps Discover Organisations on the connections screen
    Then she should see the discover organisations screen
    And she should see she is browsing as "Happy Paws Clinic"

  @P1
  Scenario: Connections screen back returns to organisation profile
    Given a registered user "Alice"
    And "Alice" is a super user of organisation "Happy Paws Clinic"
    When "Alice" opens the connected organisations screen for "Happy Paws Clinic"
    And she goes back from the connections screen
    Then she should see the organisation profile for "Happy Paws Clinic"
