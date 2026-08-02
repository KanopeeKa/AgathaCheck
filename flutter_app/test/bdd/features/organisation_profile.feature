Feature: Organisation profile
  As any visitor, signed in or not
  I want to view an organisation's public profile
  So that I can learn about a shelter before contacting them

  @P1
  Scenario: Anonymous visitor can view a discoverable organisation profile
    Given "Rescue Hearts" is discoverable with a public description
    When an anonymous visitor opens the organisation profile for "Rescue Hearts"
    Then the profile should show the organisation name and description
    And no member-only dashboard sections should appear

  @P1
  Scenario: Opted-out organisation profile is hidden from anonymous visitors
    Given "Quiet Shelter" has opted out of discovery
    When an anonymous visitor requests the public profile for "Quiet Shelter"
    Then the profile should not be found

  @P1
  Scenario: Active member can view opted-out organisation public profile
    Given "Quiet Shelter" has opted out of discovery
    And "Alice" is an active member of "Quiet Shelter"
    When "Alice" opens the organisation profile for "Quiet Shelter"
    Then the profile should show the organisation name

  @P1
  Scenario: Public profile API exposes only public-tier fields
    Given "Rescue Hearts" is discoverable with contact and legal details
    When an anonymous visitor requests the public profile API for "Rescue Hearts"
    Then the response should include only public-tier organisation fields
    And internal membership fields should not be included
