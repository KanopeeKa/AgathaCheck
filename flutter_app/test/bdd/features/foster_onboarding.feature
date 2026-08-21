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

  @P2
  Scenario: Invite new foster by email from Manage Fosters
    When "Alice" opens Manage Fosters for "Rescue Hearts"
    And "Alice" invites "bob@example.com" to foster for "Rescue Hearts" by email
    Then a foster invitation email is sent to "bob@example.com"

  @P2
  Scenario: Onboard existing member as foster from People
    Given a registered user "Eve" is an associate of "Rescue Hearts"
    When "Alice" bulk onboards "Eve" as foster for "Rescue Hearts"
    Then "Eve" receives an in-app foster invitation for "Rescue Hearts"

  @P1
  Scenario: Candidate submits foster questionnaire with AUTO_GO path
    Given a registered user "Eve" is a foster parent of "Rescue Hearts"
    When "Eve" opens the foster candidate questionnaire for "Rescue Hearts"
    And "Eve" completes the matching profile questions
    And "Eve" completes the questionnaire with all Go screening answers
    And "Eve" acknowledges and submits the questionnaire
    Then "Eve" sees the automatic Go confirmation message
    And the foster onboarding form step is complete for "Eve"
