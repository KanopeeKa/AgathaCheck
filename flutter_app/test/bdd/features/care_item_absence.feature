Feature: Care item absence review during planned absence
  As a pet parent with upcoming travel
  I want to review in-window care dates against my absence plans
  So that my carer and schedule stay aligned

  @P1
  Scenario: In-window care can be rescheduled or skipped from occurrence review during planned absence
    Given I am signed in as a guardian with a planned absence and in-window care for a pet
    And a carer is assigned for that pet on the absence
    When I open the care item for that entry
    And I open occurrence review from the absence strip
    And I skip the occurrence from the review sheet
    Then the care item absence strip should no longer show review actions

  @P1
  Scenario: Care item absence strip shows Keep with carer and Review date opens the date directly
    Given I am signed in as a guardian with a planned absence and in-window care for a pet
    And a carer is assigned for that pet on the absence
    When I open the care item for that entry
    Then I should see Keep with carer and Review date on the absence strip
    When I open occurrence review from the absence strip
    Then I should see the occurrence review sheet for the in-window care date

  @P1
  Scenario: Moving care after the trip postpones it to the day after return
    Given I am signed in as a guardian with a planned absence and in-window care for a pet
    And a carer is assigned for that pet on the absence
    When I open the care item for that entry
    And I move the in-window care date to the day after return from occurrence review
    Then the care item should show the next open date on the day after I return

  @P1
  Scenario: A date planned during the trip can be looked after by the carer
    Given I am signed in as a guardian with a planned absence and a carer assigned for the pet
    And I have planned a care date during the absence for a health entry
    When I open the care item for that entry
    And I keep that date with the carer from the absence strip
    Then the planned date during the trip should be looked after by that carer
