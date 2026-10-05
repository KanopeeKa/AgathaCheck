Feature: Care item pause and resume
  As a pet owner
  I want to pause care and resume on the right date
  So that reminders stop while care is on hold

  Background:
    Given the user is logged in
    And a pet "Rex" exists

  @P1
  Scenario: PP-2 pause without end date then resume on the suggested date
    Given "Rex" has monthly flea treatment due on "2026-06-05"
    When the user pauses the care item from the item menu without an end date
    Then the care item shows as paused
    When the user resumes the care item with the suggested date
    Then the care item has an open date on the resume date
