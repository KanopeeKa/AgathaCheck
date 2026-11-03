Feature: Absence and per-pet away plan screens
  As a pet parent planning an absence
  I want a trip screen with pet pills and a dedicated away plan per pet
  So that I can review one pet at a time without a long combined page

  @P1
  Scenario: Multi-pet absence shows one pill per pet on the absence screen
    Given I am signed in as a guardian with a saved planned absence for multiple pets
    When I open the away plan for that absence
    Then I should see a pill for each pet on the absence
    And I should not see combined who is caring sections for every pet

  @P1
  Scenario: Single-pet save lands on that pet's away plan screen
    Given I am signed in as a guardian with a pet
    When I create a planned absence for only that pet from the create form
    Then I should land on that pet's away plan screen

  @P1
  Scenario: Pet away plan shows read-only trip and See absence
    Given I am signed in as a guardian with a saved planned absence for a pet
    When I open that pet's away plan from the absence screen
    Then I should see See absence on the pet away plan screen
    And I should see who is caring for that pet only

  @P1
  Scenario: Care item absence module opens the pet away plan
    Given I am signed in as a guardian with a planned absence and in-window care for a pet
    When I open the care item for that entry
    And I open the away plan from the absence module
    Then I should see that pet's away plan screen
