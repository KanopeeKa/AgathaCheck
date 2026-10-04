@people
Feature: People directory
  Personal directory of carers and pet professionals (phase 1).

  @P2
  Scenario: Pet parent opens People from Account
    Given I am logged in as a pet parent
    When I open the Account screen
    And I choose "People"
    Then I see the People page with trusted carers and pet professionals sections

  @P2
  Scenario: Today desk shows Vet team sub-block
    Given I am logged in as a pet parent
    When I open the Pet Care dashboard
    Then I see the People desk module with a Vet team section

  @P2
  Scenario: People directory card opens person detail
    Given I am logged in as a pet parent with a saved carer contact
    When I open the People page from bottom navigation
    And I open the first people directory card
    Then I see the person detail screen

  @P2
  Scenario: Back from person detail returns to People hub
    Given I am logged in as a pet parent with a linked vet contact
    When I open the People page from bottom navigation
    And I open the first people directory card
    And I navigate back from person detail
    Then I see the People page with trusted carers and pet professionals sections
