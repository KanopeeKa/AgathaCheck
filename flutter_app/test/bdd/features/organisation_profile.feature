Feature: Organisation profile
  As any visitor, signed in or not
  I want to view an organisation's public profile
  So that I can learn about a shelter before contacting them

  Background:
    Given a registered user "Alice"
    And "Alice" is a super user of organisation "Rescue Hearts"

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

  @P1
  Scenario: Profile hero shows name beside overlapping logo
    Given "Rescue Hearts" is discoverable with a public description
    When an anonymous visitor opens the organisation profile for "Rescue Hearts"
    Then the profile hero should show the name beside a large overlapping logo

  @P1
  Scenario: Super admin sees edit action without overflow menu on profile
    When "Alice" opens the organisation profile for "Rescue Hearts"
    Then she should see an edit organisation action on the profile
    And the profile should not show an overflow menu

  @P1
  Scenario: Member sees permission-gated profile nav rows without previews
    Given a registered user "Bob"
    And "Bob" is a member of "Rescue Hearts" with role "associate"
    When "Bob" opens the organisation profile for "Rescue Hearts"
    Then he should see a profile nav row for "People"
    And he should see a profile nav row for "Pets"
    And he should not see inline pet previews on the profile

  @P1
  Scenario: Super Admin sees Organisation Administration nav row on profile
    When "Alice" opens the organisation profile for "Rescue Hearts"
    Then she should see a profile nav row for "Organisation Administration"
    And she should not see inline section previews on the profile

  @P1
  Scenario: Foster Admin does not see Organisation Administration nav row
    Given "Alice" is a Foster Admin member of "Rescue Hearts"
    When "Alice" opens the organisation profile for "Rescue Hearts"
    Then she should not see a profile nav row for "Organisation Administration"
