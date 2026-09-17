Feature: Care Suggestion
  As a pet owner
  I want Agatha to suggest recurring care rhythms for my pet
  So that I can keep on top of preventive care between vet visits

  Background:
    Given the user is logged in
    And an adult pet eligible for a care suggestion exists

  @P1
  Scenario: A care suggestion surfaces on the pet profile contextual slot
    When the user views the pet's profile
    Then a "Suggested by Agatha" card should appear in the contextual slot
    And the card should offer accept and not-relevant actions

  @P1
  Scenario: A care suggestion never appears in the Actions (/pc/events) list
    Given the pet is eligible for a care suggestion
    When the user opens the Actions (/pc/events) list
    Then no "Suggested by Agatha" card should appear in the list

  @P1
  Scenario: Accepting a suggestion creates a rhythm and removes the card
    When the user views the pet's profile
    And the user accepts the suggestion
    Then the suggestion card should no longer appear
    And a recurring care rhythm should be created for the pet
