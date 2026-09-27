@people
Feature: People directory
  Personal directory of carers and pet professionals (phase 1).

  @P2
  Scenario: Pet parent opens People from Account
    Given I am logged in as a pet parent
    When I open the Account screen
    And I choose "People"
    Then I see the People page with trusted carers and pet professionals sections
