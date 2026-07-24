Feature: Foster onboarding and approval
  As an organisation admin
  I want to manage foster families from an operational screen
  So that I can see who is fostering and add manual foster records

  Background:
    Given an organisation "Rescue Hearts" of type "Charity"
    And "Alice" is a super user of "Rescue Hearts"

  @P2
  Scenario: Opening Manage Fosters from organisation menu
    When "Alice" opens Manage Fosters for "Rescue Hearts"
    Then the Manage Fosters screen shows tabs for operational views

  @P2
  Scenario: Viewing fosters currently fostering
    Given a registered user "Eve" is a foster parent of "Rescue Hearts"
    And "Max" is fostered from "Rescue Hearts" to "Eve"
    When "Alice" opens Manage Fosters for "Rescue Hearts"
    And "Alice" selects the Fostering tab
    Then "Eve" should appear in the foster list

  @P2
  Scenario: Adding a foster manually
    When "Alice" opens Manage Fosters for "Rescue Hearts"
    And "Alice" adds a foster manually named "Bob" with email "bob@example.com"
    Then "Bob" should appear in the foster list
