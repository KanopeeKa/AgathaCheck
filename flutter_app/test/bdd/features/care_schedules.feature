Feature: Care schedules
  As a pet owner
  I want schedule rules to apply when I record care late or in bulk
  So that the next dates stay predictable

  Background:
    Given the user is logged in
    And a pet "Bella" exists

  @P1
  Scenario: Missed fixed-schedule care can be marked as done together on the care item
    Given "Bella" has a daily medication "Stack Meds" with two overdue dates today
    When the user opens the care item "Stack Meds"
    And the user taps "Mark all as done" on the care item
    Then every overdue date for "Stack Meds" should be recorded

  @P1
  Scenario: Care older than three days can still be recorded from history
    Given "Bella" has a completed care entry "Grooming" from last month
    When the user opens history for "Grooming"
    And the user opens the history occurrence for "Grooming"
    Then the occurrence screen should allow recording as done

  @P1
  Scenario: Care done after its due date keeps the next planned date and offers to change it
    Given "Bella" has a daily medication "Apoquel" scheduled at "08:00" and "18:00"
    And it is 15:00, so the 08:00 date is overdue
    When the user records the 08:00 date as done today
    Then the 18:00 date should still be planned
    And the done snackbar should offer to change the completion date

  @P1
  Scenario: A remembered choice is applied without asking again
    Given "Bella" has after-it's-done care "Flea" with late completion choice "Keep"
    When the user records "Flea" late without a date prompt
    Then the next planned date should follow the remembered choice

  @P1
  Scenario: Changing when care was done moves the next date of after-it's-done care
    Given "Bella" has after-it's-done care "Flea" with a completed occurrence
    When the user changes when that occurrence was done
    Then the next planned date for "Flea" should update
